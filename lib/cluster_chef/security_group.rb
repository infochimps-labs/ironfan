
# ip_permissions[
#   {"groups"=>[{"userId"=>"484232731444", "groupName"=>"ham"}], "ipRanges"=>[], "ipProtocol"=>"tcp", "fromPort"=>1, "toPort"=>65535},
#   {"groups"=>[{"userId"=>"484232731444", "groupName"=>"ham"}], "ipRanges"=>[], "ipProtocol"=>"udp", "fromPort"=>1, "toPort"=>65535},
#   {"groups"=>[{"userId"=>"484232731444", "groupName"=>"ham"}], "ipRanges"=>[], "ipProtocol"=>"icmp", "fromPort"=>-1, "toPort"=>-1},
#   {"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/0"}], "ipProtocol"=>"tcp", "fromPort"=>22, "toPort"=>22},
#   {"groups"=>[], "ipRanges"=>[{"cidrIp"=>"0.0.0.0/0"}], "ipProtocol"=>"tcp", "fromPort"=>80, "toPort"=>80}
# ]


module ClusterChef
  module Cloud
    class SecurityGroup < DslObject
      has_keys :name, :description, :owner_id
      def initialize cloud, group_name, group_description=nil, group_owner_id=nil
        super()
        name group_name
        description group_description || "cluster_chef generated group #{group_name}"
        @cloud         = cloud
        @group_authorizations = []
        @range_authorizations = []
        owner_id group_owner_id || Chef::Config.knife[:aws_account_id]
      end

      def connection
        @cloud.connection
      end

      @@all = nil
      def all
        self.class.all(connection)
      end
      def self.all(connection)
        return @@all if @@all
        get_all(connection)
      end
      def self.get_all connection
        groups_list = connection.security_groups.all
        @@all = groups_list.inject({}) do |hsh, group|
          hsh[group.name] = group ; hsh
        end
      end

      def get
        all[name] || @cloud.connection.security_groups.get(name)
      end

      def self.get_or_create group_name, description, connection
        group = all(connection)[group_name] || connection.security_groups.get(group_name)
        if ! group
          group = all(connection)[group_name] = Fog::AWS::Compute::SecurityGroup.new(:name => group_name, :description => description, :connection => connection)
          group.save
        end
        group
      end

      def authorize_group_and_owner group, owner_id=nil
        @group_authorizations << [group, owner_id]
      end

      # Alias for authorize_group_and_owner
      def authorize_group *args
        authorize_group_and_owner *args
      end

      def authorize_port_range range, cidr_ip = '0.0.0.0/0', ip_protocol = 'tcp'
        @range_authorizations << [range, cidr_ip, ip_protocol]
      end

      def group_permission_already_set? group, authed_group, authed_owner
        return false if group.ip_permissions.blank?
        group.ip_permissions.any? do |existing_permission|
          existing_permission["groups"].include?({"userId"=>authed_owner, "groupName"=>authed_group}) &&
            existing_permission["fromPort"] == 1 &&
            existing_permission["toPort"] == 65535
        end
      end

      def range_permission_already_set? group, range, cidr_ip, ip_protocol
        return false if group.ip_permissions.blank?
        group.ip_permissions.include?({"groups"=>[], "ipRanges"=>[{"cidrIp"=>cidr_ip}], "ipProtocol"=>ip_protocol, "fromPort"=>range.first, "toPort"=>range.last})
      end

      def run
        group = self.class.get_or_create name, description, connection
        @group_authorizations.uniq.each do |authed_group, authed_owner|
          authed_owner ||= self.owner_id
          next if group_permission_already_set?(group, authed_group, authed_owner)
          warn ['authorizing group', authed_group, authed_owner].inspect
          self.class.get_or_create(authed_group, "Authorized to access nfs server", connection)
          group.authorize_group_and_owner(authed_group, authed_owner)
        end
        @range_authorizations.uniq.each do |range, cidr_ip, ip_protocol|
          next if range_permission_already_set?(group, range, cidr_ip, ip_protocol)
          warn ['authorizing range', range, { :cidr_ip => cidr_ip, :ip_protocol => ip_protocol }]
          group.authorize_port_range(range, { :cidr_ip => cidr_ip, :ip_protocol => ip_protocol })
        end
      end

    end
  end
end

