module Ironfan
  module Dsl
    class Cloud < Ironfan::Dsl::Builder
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
    end

    class VirtualBox < Cloud
    end

  end
end