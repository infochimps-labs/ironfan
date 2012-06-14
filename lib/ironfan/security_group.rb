module Ironfan
  module Cloud
    class SecurityGroup < DslObject
      has_keys :name, :description, :owner_id, :group_id
      attr_reader :group_authorizations
      attr_reader :range_authorizations
      def initialize cloud, group_name, group_description=nil, group_owner_id=nil
        super()

        @@vpc = cloud.vpc if cloud.vpc.present?

        if (@@vpc)
          group_name = @@vpc + "-" + group_name
          set :name, group_name.to_s
          description group_description || "ironfan generated vpc group #{group_name}"
        else
          set :name, group_name.to_s
          description group_description || "ironfan generated group #{group_name}"
        end
        @cloud         = cloud
        @group_authorizations = []
        @group_authorized_by  = []
        @range_authorizations = []
        owner_id(group_owner_id || Chef::Config[:knife][:aws_account_id])
      end

      @@vpc = nil

      @@all = nil

      def all
        self.class.all
      end

      def self.all
        return @@all if @@all
        get_all
      end

      def self.get_all
        if (@@vpc)
          groups_list = Ironfan.fog_connection.security_groups.all({ "group-name" => "#{@@vpc}-*" })
        else
          groups_list = Ironfan.fog_connection.security_groups.all
        end
        @@all = groups_list.inject(Mash.new) do |hsh, fog_group|
          # AWS security_groups are strangely case sensitive, allowing upper-case but colliding regardless
          #  of the case. This forces all names to lowercase, and matches against that below.
          #  See https://github.com/infochimps-labs/ironfan/pull/86 for more details.
          hsh[fog_group.name.downcase] = fog_group ; hsh
        end
      end

      def get
        all[name] || Ironfan.fog_connection.security_groups.get(name)
      end

      def self.get_or_create(group_name, description)
        group_name = group_name.to_s.downcase
        # FIXME: the '|| Ironfan.fog' part is probably unnecessary
        fog_group = all[group_name] || Ironfan.fog_connection.security_groups.get(group_name)
        unless fog_group
          self.step(group_name, "creating (#{description})", :green)
          fog_group = all[group_name] = Ironfan.fog_connection.security_groups.new(:name => group_name, :description => description, :connection => Ironfan.fog_connection, :vpc_id => @@vpc)
          fog_group.save
        end
        fog_group
      end

      def authorize_group(group_name, owner_id=nil)
        @group_authorizations << [group_name.to_s, owner_id]
      end

      def authorized_by_group(other_name)
        @group_authorized_by << other_name.to_s
      end

      def authorize_port_range(range, cidr_ip = '0.0.0.0/0', ip_protocol = 'tcp')
        range = (range .. range) if range.is_a?(Integer)
        @range_authorizations << [range, cidr_ip, ip_protocol]
      end

      def group_permission_already_set?(fog_group, other_name, authed_owner)
        return false if fog_group.ip_permissions.nil?
        fog_group.ip_permissions.any? do |existing_permission|
          existing_permission["groups"].include?({"userId" => authed_owner, "groupName" => other_name}) &&
          existing_permission["fromPort"] == 1 &&
          existing_permission["toPort"]   == 65535
        end
      end

      def range_permission_already_set?(fog_group, range, cidr_ip, ip_protocol)
        return false if fog_group.ip_permissions.nil?
        fog_group.ip_permissions.include?(
        { "groups"=>[], "ipRanges"=>[{"cidrIp"=>cidr_ip}],
          "ipProtocol"=>ip_protocol, "fromPort"=>range.first, "toPort"=>range.last})
      end

      # FIXME: so if you're saying to yourself, "self, this is some soupy gooey
      # code right here" then you and your self are correct. Much of this is to
      # work around old limitations in the EC2 api. You can now treat range and
      # group permissions the same, and we should.

      def run
        fog_group = self.class.get_or_create(name, description)
        @group_authorizations.uniq.each do |other_name, authed_owner|
          authed_owner ||= self.owner_id
          next if group_permission_already_set?(fog_group, other_name, authed_owner)
          step("authorizing access from all machines in #{other_name} to #{name}", :blue)
          self.class.get_or_create(other_name, "Authorized to access #{name}")
          begin  fog_group.authorize_group_and_owner(other_name, authed_owner)
          rescue StandardError => err ; handle_security_group_error(err) ; end
        end
        @group_authorized_by.uniq.each do |other_name|
          authed_owner = self.owner_id
          other_group = self.class.get_or_create(other_name, "Authorized for access by #{self.name}")
          next if group_permission_already_set?(other_group, self.name, authed_owner)
          step("authorizing access to all machines in #{other_name} from #{name}", :blue)
          begin  other_group.authorize_group_and_owner(self.name, authed_owner)
          rescue StandardError => err ; handle_security_group_error(err) ; end
        end
        @range_authorizations.uniq.each do |range, cidr_ip, ip_protocol|
          next if range_permission_already_set?(fog_group, range, cidr_ip, ip_protocol)
          step("opening #{ip_protocol} ports #{range} to #{cidr_ip}", :blue)
          begin  fog_group.authorize_port_range(range, { :cidr_ip => cidr_ip, :ip_protocol => ip_protocol })
          rescue StandardError => err ; handle_security_group_error(err) ; end
        end
      end

      def handle_security_group_error(err)
        if (/has already been authorized/ =~ err.to_s)
          Chef::Log.debug err
        else
          ui.warn(err)
        end
      end

      def self.step(group_name, desc, *style)
        ui.info("  group #{"%-15s" % (group_name+":")}\t#{ui.color(desc.to_s, *style)}")
      end

      def step(desc, *style)
        self.class.step(self.name, desc, *style)
      end

    end
  end
end
