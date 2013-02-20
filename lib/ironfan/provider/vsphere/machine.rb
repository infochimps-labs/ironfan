module Ironfan
  class Provider
    class Vsphere

      class Machine < Ironfan::IaasProvider::Machine

        def self.shared?()      false;  end
        def self.multiple?()    false;  end
        def self.resource_type()        :machine;   end
        def self.expected_ids(computer) [computer.server.full_name];   end

      end

    end
  end
end
