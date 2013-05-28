require 'digest/md5'

module Ironfan
  class Dsl

    class Compute < Ironfan::Dsl
      def rds(*attrs,&block)            cloud(:rds,*attrs,&block);      end
    end

    class Rds < Cloud
      magic :autoupgrade,               :boolean,       :default => true
      magic :availability_zones,        Array,          :default => ['us-east-1d']
      magic :backup_retention,          Integer,        :default => 1
      magic :charset,                   String,         :default => nil
      magic :dbname,                    String,         :default => ->{ dbname }
      magic :default_availability_zone, String,         :default => ->{ availability_zones.first }
      magic :engine,                    String,         :default => ->{ engines.first }
      magic :engines,                   Array,          :default => ["MySQL", "oracle-se1", "oracle-se", "oracle-ee", "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web"]
      magic :flavor,                    String,         :default => "db.t1.micro"
      magic :iops,                      Integer,        :default => 1000
      magic :license_model,             String,         :default => nil
      magic :multi_availability_zone,   :boolean,       :default => false
      magic :password,                  String,         :default => nil
      magic :port,                      Integer,        :default => ->{ port }     
      magic :preferred_backup_window,    String,        :default => nil  # Format hh24:mi-hh24:mi.  Needs to be at least 30 minutes, UTC,
      magic :preferred_maintenance_window, String,      :default => nil  # Format ddd:hh24:mi-ddd:hh24:mi.  Minimum 30 minutes, UTC
      magic :provider,                  Whatever,       :default => Ironfan::Provider::Rds
      magic :size,                      Integer,        :default => 50 # Size in GB
      collection :security_groups,      Ironfan::Dsl::Rds::SecurityGroup, :key_method => :name
      magic :username,                  String,         :default => nil
      magic :version,                   String,         :default => nil
      
      def receive_provider(obj)
        if obj.is_a?(String)
          write_attribute :provider, Gorillib::Inflector.constantize(Gorillib::Inflector.camelize(obj.gsub(/\./, '/')))
        else
          super(obj)
        end
      end

      # This is a dummy function to fill Ironfan's requirements.
      def implied_volumes
        []
      end

      def dbname
        return "ORCL" if ["oracle-se1", "oracle-se", "oracle-ee"].include?(engine)
        return nil 
      end

      def port(port=nil)
        return port unless port.nil?
        return 3306 if engine == "MySQL"
        return 1521 if ["oracle-se1", "oracle-se", "oracle-ee"].include?(engine)
        return 1433 if ["sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web"].include?(engine)
      end

      def to_display(style,values={})
        return values if style == :minimal

        values["Engine"] =            engine
        values["AZ"] =                default_availability_zone
        return values if style == :default

#        values["Public IP"] =        elastic_ip if elastic_ip
        values
      end

      class SecurityGroup < Ironfan::Dsl
        field :name,                    String
        field :ec2_authorizations,      Array, :default => []
        field :ip_authorizations,       Array, :default => []

        def authorize_ip_range(cidr_ip = '0.0.0.0/0')
          ip_authorizations << cidr_ip
          ip_authorizations.compact!
          ip_authorizations.uniq!
        end

        def authorize_ec2_group(ec2_security_group)
          ec2_authorizations << ec2_security_group
          ec2_authorizations.compact!
          ec2_authorizations.uniq!
        end
      end # SecurityGroup

    end
  end
end

