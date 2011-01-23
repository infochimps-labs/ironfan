
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
      def initialize cloud, group_name, group_description=nil
        super()
        name group_name
        description group_description || "cluster_chef generated group #{group_name}"
        @cloud         = cloud
        @group_authorizations = []
        @range_authorizations = []
      end

      def connection
        @cloud.connection
      end

      @@all = nil
      def all
        return @@all if @@all
        get_all
      end
      def get_all
        groups_list = @cloud.connection.security_groups.all
        @@all = groups_list.inject({}) do |hsh, group|
          hsh[group.name] = group ; hsh
        end
      end

      def get
        all[name] || @cloud.connection.security_groups.get(name)
      end

      def authorize_group_and_owner group, owner_id=nil
        @group_authorizations << [group, owner_id]
      end

      def authorize_port_range range, cidr_ip = '0.0.0.0/0', ip_protocol = 'tcp'
        @range_authorizations << [range, cidr_ip, ip_protocol]
      end

      def owner_id
        Chef::Config.knife[:aws_account_id]
      end

      def converge!
        group = get
        if ! group
          group = all[name] = Fog::AWS::Compute::SecurityGroup.new(:name => name, :description => description, :connection => connection)
          group.save
        end
        p group
        @group_authorizations.uniq.each do |authed_group, authed_owner|
          authed_owner ||= self.owner_id
          next if group.ip_permissions.include?({"groups"=>[{"userId"=>authed_owner, "groupName"=>authed_group}], "ipRanges"=>[], "ipProtocol"=>'tcp', "fromPort"=> 1, "toPort"=> 65535 })
          p group.ip_permissions
          p( {"groups"=>[{"userId"=>authed_owner, "groupName"=>authed_group}], "ipRanges"=>[], "ipProtocol"=>'tcp', "fromPort"=> 1, "toPort"=> 65535 })
          Chef::Log.info ['authorizing group', authed_group, authed_owner]
          group.authorize_group_and_owner(authed_group, authed_owner)
        end
        @range_authorizations.uniq.each do |range, cidr_ip, ip_protocol|
          next if group.ip_permissions.include?({"groups"=>[], "ipRanges"=>[{"cidrIp"=>cidr_ip}], "ipProtocol"=>ip_protocol, "fromPort"=>range.first, "toPort"=>range.last})
          Chef::Log.info ['authorizing', range, { :cidr_ip => cidr_ip, :ip_protocol => ip_protocol }]
          group.authorize_port_range(range, { :cidr_ip => cidr_ip, :ip_protocol => ip_protocol })
        end
      end

    end
  end
end

