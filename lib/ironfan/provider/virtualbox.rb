module Ironfan
  module Provider
    module VirtualBox

      # 
      # Resources
      #
      class Instance < Ironfan::Provider::Instance
      end

      # 
      # Connection
      #
      class Connection < Ironfan::Provider::IaasConnection
      end

    end
  end
end