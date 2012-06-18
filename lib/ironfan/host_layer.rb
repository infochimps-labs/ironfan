require 'net/ssh'

module Ironfan
  #
  # Ironfan::Server methods that handle host actions
  #
  Server.class_eval do

    def host_server
      Chef::Log.debug "in host_layer -> Ironfan::Server.host_server"
      return @host_server unless @host_server.nil?
      @host_server = Ironfan::Host.new
      @host_server.id = "#{cloud.target_user}@#{cloud.target_address}:#{cloud.target_port}"
      @host_server.public_ip_address = cloud.target_address
      options = {}
      options[:password] = cloud.target_password unless cloud.target_password.nil?
      options[:keys]     = [ Ironfan::HostKey.new(cloud.target_key).filename ] unless cloud.target_key.nil?
      options[:timeout]  = cloud.target_timeout
      begin
        Net::SSH.start(cloud.target_address, cloud.target_user, options) do |ssh|
          @host_server.state = 'running'
        end
      rescue Net::SSH::AuthenticationFailed, Errno::ECONNREFUSED
        Chef::Log.warn $!
        @host_server.state = 'inaccessible'
      rescue Timeout::Error, Errno::ETIMEDOUT
        Chef::Log.warn $!
        @host_server.state = 'not running'
      end
      @host_server
    end

  end
  
  class Host < Hash
    attr_accessor :id, :state, :public_ip_address
  end


  class HostKey < PrivateKey
    def body
      return @body if @body
      load
      @body
    end

    def key_dir
      return Chef::Config.host_key_dir      if Chef::Config.host_key_dir
      dir = "#{ENV['HOME']}/.chef/credentials/host_keys"
      warn "Please set 'host_key_dir' in your knife.rb. Will use #{dir} as a default"
      dir
    end
  end
end
