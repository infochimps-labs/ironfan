# Providers present a lightweight wrapper for various third-party services,
#   such as Chef's node and client APIs, and Amazon's EC2 APIs. This allows
#   Ironfan ask specialized questions (such as whether a given resource 
#   matches
module Ironfan
  class Provider < Builder

    def self.receive(obj,&block)
      obj[:_type] = case obj[:name]
        when    :chef;          Chef
        when    :ec2;           Ec2
        when    :virtualbox;    VirtualBox
        else;   raise "Unsupported provider #{obj[:name]}"
      end unless native?(obj)
      super
    end

    #   
    #   EXPECTED CALL-SIGN
    #
    # #
    # # Discovery
    # #
    # def load!(machines)                 end
    # def correlate!(machines)            end
    # def validate!(machines)             end
    #
    # #
    # # Manipulation
    # #
    # def create_dependencies!(machines)  end
    # def create_instances!(machines)     end
    # def destroy!(machines)              end
    # def save!(machines)                 end
    #
    # #
    # # Instance Manipulation
    # #
    # def start_instances!(machines)      end
    # def stop_instances!(machines)       end

    class Resource < Builder
      field             :adaptee,       Whatever
      field             :users,         Array,          :default => []
      field             :bogus,         Array,          :default => []

      attr_accessor     :owner

      def bogus?()      !bogus.empty?;                  end

    end

    class ResourceCollection < Gorillib::ModelCollection
      self.key_method = :name

      #
      #   EXPECTED CALL-SIGN
      #
      # #
      # # Discovery
      # #
      # def load!(machines)               end
      # def correlate!(machines)          end
      # def validate!(machines)           end
      #
      # #
      # # Manipulation
      # #
      # def create!(machines)             end
      # def destroy!(machines)            end
      # def save!(machines)               end
      #
      # #
      # # Instance Manipulation
      # #
      # def start!(machines)              end
      # def stop!(machines)               end
    end
  end

  class IaasProvider < Provider
    collection          :instances,     Instance

    class Instance < Resource
    end
  end

end