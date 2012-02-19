module Vagrant
  module Provisioners
    class IronfanChefClient < Vagrant::Provisioners::ChefClient
      class Config < Vagrant::Provisioners::ChefClient::Config
        attr_accessor :upload_client_key
      end
      def self.config_class() Config ; end

      def upload_validation_key
        super()
        if config.upload_client_key
          # env[:ui].info I18n.t("vagrant.provisioners.chef.upload_client_key")
          host_client_key = File.expand_path(config.upload_client_key)
          env[:vm].channel.upload(host_client_key, tmp_client_key_path)
          env[:vm].channel.sudo("mv #{tmp_client_key_path} #{config.client_key_path}")
          env[:vm].channel.sudo("chown root #{config.client_key_path}")
          env[:vm].channel.sudo("chmod 600  #{config.client_key_path}")
        end
      end

      def tmp_client_key_path
        File.join(config.provisioning_path, "client.pem")
      end

    end
  end
end
