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
    # def load!(computers)                 end
    # def correlate!(computers)            end
    # def validate!(computers)             end
    #
    # #
    # # Manipulation
    # #
    # def create_dependencies!(computers)  end
    # def create_machines!(computers)     end
    # def destroy!(computers)              end
    # def save!(computers)                 end
    #
    # #
    # # Machine Manipulation
    # #
    # def start_machines!(computers)      end
    # def stop_machines!(computers)       end

    class Resource < Builder
      @@known = {}
      field             :adaptee,       Whatever
      field             :users,         Array,          :default => []
      field             :bogus,         Array,          :default => []

      def bogus?()      !bogus.empty?;                  end

      #
      # Utilities
      #
      def self.remember(resource,options={})
        index = options[:id] || resource.name
        index += options[:append_id] if options[:append_id]
        self.known[index] = resource
      end

      # Register and return the (adapted) object with the collection
      def self.register(native)
        result = new(:adaptee => native)
        remember result unless result.nil?
      end

      def self.recall?(id)
        self.known.include? id
      end

      def self.recall(id=nil)
        self.known[id] or self.known
      end

      def self.forget(id)
        self.known.delete(id)
      end

      # Provide a separate namespace in @@known for each subclass
      def self.known
        @@known[self.name] ||= {}
      end
    end

  end

  class IaasProvider < Provider
    collection          :machines,     Machine

    class Machine < Resource
    end
  end

end