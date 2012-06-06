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
      begin
        Net::SSH.start(cloud.target_address, cloud.target_user, :password => cloud.target_password) do |ssh|
          @host_server.public_ip_address = ssh.host
          @host_server.state = 'running'
        end
      rescue Net::SSH::AuthenticationFailed, Errno::ECONNREFUSED
        Chef::Log.warn $!
        @host_server.state = 'inaccessible'
      end
      @host_server
    end

  end
  
  class Host < Hash
    attr_accessor :id, :state, :public_ip_address
  end
end
