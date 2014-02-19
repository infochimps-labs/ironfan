require 'digest/md5'

module Ironfan
  class Dsl

    class Compute < Ironfan::Dsl
      def static(*attrs,&block)            cloud(:static,*attrs,&block);      end
    end

    class Static < Cloud

      magic :private_ip,                String
      magic :public_ip,                 String
      magic :private_hostname,          String
      magic :public_hostname,           String
      magic :keypair,                   String
      magic :provider,                  Whatever,       :default => Ironfan::Provider::Static

      magic :availability_zones,        Array,          :default => []
      magic :backing,                   String,         :default => nil
      magic :bits,                      Integer,        :default => 64
      magic :bootstrap_distro,          String,         :default => "ubuntu12.04-ironfan"
      magic :chef_client_script,        String
      magic :default_availability_zone, String,         :default => "none"
      magic :ebs_optimized,             :boolean,       :default => false
      magic :flavor,                    String,         :default => 'whatever'
      magic :image_id,                  String
      magic :image_name,                String
      magic :monitoring,                String
      magic :mount_ephemerals,          Hash,           :default => {}
      magic :permanent,                 :boolean,       :default => false
      magic :placement_group,           String
      magic :elastic_ip,                String
      magic :auto_elastic_ip,           String
      magic :allocation_id,             String
      magic :region,                    String,         :default => 'none'
      collection :security_groups,      Ironfan::Dsl::SecurityGroup, :key_method => :name
      magic :ssh_user,                  String,         :default => 'ubuntu'
      magic :ssh_identity_dir,          String,         :default => ->{ Chef::Config.openstack_key_dir }
      magic :subnet,                    String
      magic :validation_key,            String,         :default => ->{ IO.read(Chef::Config.validation_key) rescue '' }
      magic :vpc,                       String
      magic :dns_search_domain,         String,         :default => 'static'

      def to_display(style,values={})
        return values if style == :minimal

        values["Private IP"] =   private_ip
        values["Public IP"] =    public_ip
        values
      end

      def flavor_info
        return nil
      end

      def implied_volumes
        []
      end
    end
  end
end

