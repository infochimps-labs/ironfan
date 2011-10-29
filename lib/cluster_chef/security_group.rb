module ClusterChef
  module Cloud

    class SecurityGroup < DslObject
      has_keys :name, :description, :owner_id
      attr_reader :group_authorizations
      attr_reader :range_authorizations

      def initialize cloud, group_name, group_description=nil, group_owner_id=nil
        super()
        set :name, group_name.to_s
        description group_description || "cluster_chef generated group #{group_name}"
        @cloud         = cloud
        @group_authorizations = []
        @range_authorizations = []
        owner_id group_owner_id || Chef::Config[:knife][:aws_account_id]
      end

      @@all = nil
      def all
        self.class.all
      end
      def self.all
        return @@all if @@all
        get_all
      end
      def self.get_all
        groups_list = ClusterChef.fog_connection.security_groups.all
        @@all = groups_list.inject(Mash.new) do |hsh, group|
          hsh[group.name] = group ; hsh
        end
      end

      def get
        all[name] || ClusterChef.fog_connection.security_groups.get(name)
      end

      def self.get_or_create group_name, description
        group = all[group_name] || ClusterChef.fog_connection.security_groups.get(group_name)
        if ! group
          Chef::Log.info "Creating security group #{group_name} (#{description})"
          group = all[group_name] = ClusterChef.fog_connection.security_groups.new(:name => group_name, :description => description, :connection => ClusterChef.fog_connection)
          group.save
        end
        group
      end

      def authorize_group_and_owner group, owner_id=nil
        @group_authorizations << [group.to_s, owner_id]
      end

      # Alias for authorize_group_and_owner
      def authorize_group *args
        authorize_group_and_owner *args
      end

      def authorize_port_range range, cidr_ip = '0.0.0.0/0', ip_protocol = 'tcp'
        range = (range .. range) if range.is_a?(Integer)
        @range_authorizations << [range, cidr_ip, ip_protocol]
      end

      def group_permission_already_set? group, authed_group, authed_owner
        return false if group.ip_permissions.nil?
        group.ip_permissions.any? do |existing_permission|
          existing_permission["groups"].include?({"userId"=>authed_owner, "groupName"=>authed_group}) &&
            existing_permission["fromPort"] == 1 &&
            existing_permission["toPort"] == 65535
        end
      end

      def range_permission_already_set? group, range, cidr_ip, ip_protocol
        return false if group.ip_permissions.nil?
        group.ip_permissions.include?({"groups"=>[], "ipRanges"=>[{"cidrIp"=>cidr_ip}], "ipProtocol"=>ip_protocol, "fromPort"=>range.first, "toPort"=>range.last})
      end

      def run
        group = self.class.get_or_create name, description
        @group_authorizations.uniq.each do |authed_group, authed_owner|
          authed_owner ||= self.owner_id
          next if group_permission_already_set?(group, authed_group, authed_owner)
          Chef::Log.info ['authorizing group for', self.name, authed_group, authed_owner].inspect
          self.class.get_or_create(authed_group, "Authorized to access nfs server")
          begin  group.authorize_group_and_owner(authed_group, authed_owner)
          rescue StandardError => e ; Chef::Log.warn e ; end
        end
        @range_authorizations.uniq.each do |range, cidr_ip, ip_protocol|
          next if range_permission_already_set?(group, range, cidr_ip, ip_protocol)
          Chef::Log.info ['authorizing range for', self.name, range, { :cidr_ip => cidr_ip, :ip_protocol => ip_protocol }]
          begin  group.authorize_port_range(range, { :cidr_ip => cidr_ip, :ip_protocol => ip_protocol })
          rescue StandardError => e ; Chef::Log.warn e ; end
        end
      end

    end
  end
end
