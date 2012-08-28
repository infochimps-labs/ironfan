module Ironfan
  class Dsl

    class Cloud < Ironfan::Dsl
      magic :default_cloud,           :boolean,       :default => false

      # Factory out to subclasses 
      def self.receive(obj,&block)
        obj[:_type] = case obj[:name]
          when        :ec2;           Ec2
          when        :virtualbox;    VirtualBox
          else;       raise "Unsupported cloud #{obj[:name]}"
        end unless native?(obj)
        super
      end

      def implied_volumes()     Ironfan.noop(self,__method__,*p);      end
    end

  end
end