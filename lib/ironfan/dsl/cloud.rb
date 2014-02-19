module Ironfan
  class Dsl

    class Cloud < Ironfan::Dsl
      magic :default_cloud,           :boolean,       :default => false

      # Factory out to subclasses
      def self.receive(obj, &block)
        if obj.is_a?(Hash)
          obj = obj.symbolize_keys
          obj[:_type] ||=
            case obj[:name]
            when :ec2        then Ec2
            when :virtualbox then VirtualBox
            when :vsphere    then Vsphere
            when :rds        then Rds
            when :openstack  then OpenStack
            when :static     then Static
            else raise "Unsupported cloud #{obj[:name]}"
            end
        end
        super
      end

      def implied_volumes()     Ironfan.noop(self,__method__,*p);      end
    end

  end
end
