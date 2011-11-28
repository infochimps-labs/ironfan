
module ClusterChef
  module VagrantUtils

    # Fill cloud hash with virtualbox heuristics
    def get_cloud_from_virtualbox
      return unless node[:virtualization] && node[:virtualization][:system] == "vbox"
      node[:cloud] ||= Mash.new()
      node[:cloud][:public_ips]      = node[:virtualbox]['public_ips']
      node[:cloud][:private_ips]     = node[:virtualbox]['private_ips']
      node[:cloud][:public_ipv4]     = node[:virtualbox]['public_ipv4']
      node[:cloud][:public_hostname] = node[:virtualbox]['public_hostname']
      node[:cloud][:local_ipv4]      = node[:virtualbox]['local_ipv4']
      node[:cloud][:local_hostname]  = node[:virtualbox]['local_hostname']
      node[:cloud][:provider]        = "virtualbox"
    end

    #
    # File the interfaces into public and private, using the following rules:
    #
    # * host_only:   ips in 33.33.xx.xx by convention
    # * private_ips:
    #   - host-only ips
    #   - in IPv4 private address space (10.xx.xx.xx, 172.16.xx.xx to 172.31.xx.xx, and 192.168.xx.xx)
    # * public_ips:  everything else
    #
    # and this exception:
    # * if no public_ips, the first non-host-only ip is relocated to public_ips,
    #   under the assumption that is the interface open to the host machine
    #
    def get_virtualbox_network_info
      return unless node[:virtualization] && node[:virtualization][:system] == "vbox"
      node[:virtualbox] ||= Mash.new
      node[:virtualbox][:public_ips]    = []
      node[:virtualbox][:private_ips]   = []
      node[:virtualbox][:host_only_ips] = []
      get_ips_from_network.each do |ip|
        case virtualbox_classify_interface(ip)
        when :private_24, :private_20, :private_16
          node[:virtualbox][:private_ips] << ip
        when :host_only
          node[:virtualbox][:private_ips] << ip
          node[:virtualbox][:host_only_ips] << ip
        else
          node[:virtualbox][:public_ips] << ip
        end
      end
      if node[:virtualbox][:public_ips].empty?
        first_private_ip = (node[:virtualbox][:private_ips] - node[:virtualbox][:host_only_ips]).first
        if first_private_ip
          node[:virtualbox][:public_ips]   = [first_private_ip]
          node[:virtualbox][:private_ips] -= [first_private_ip]
        end
      end
      node[:virtualbox][:local_ipv4]      = node[:virtualbox][:host_only_ips].first || node[:virtualbox][:private_ips].first
      node[:virtualbox][:public_ipv4]     = node[:virtualbox][:public_ips].first
      node[:virtualbox][:public_hostname] = node[:fqdn]
    end

    #
    # Lists ipv4 address of all non-Loopback interfaces, with the address
    # corresponding to network[:default_interface] listed first.
    #
    def get_ips_from_network
      ips = []
      node[:network][:interfaces].sort_by{|k,v| k.to_s }.each do |name, info|
        next if info[:encapsulation] == 'Loopback'
        ip = info[:addresses].keys.detect{|addr| info[:addresses][addr][:family] == 'inet' }
        if name == node[:network][:default_interface]
          ips.unshift(ip)
        else
          ips.push(ip)
        end
      end
      ips.flatten.compact.uniq
    end

    #
    # * `:private_xx`: ipv4 private address space IPs are classified by which private space
    # * `:host_only`:  33.33.xx.xx -- by convention, these are host-only (private) subnets
    # * `:public`:     anything else
    #
    # Note that 192.168.xx.xx addresses are classified as **private**, even if that
    # address is used to poke out to your local router's LAN subnet.
    #
    # @returns [Symbol] one of [:private_24, :private_20, :private_16, :host_only, :public]
    def virtualbox_classify_interface(ipv4)
      case ipv4
        # http://en.wikipedia.org/wiki/IP_address#IPv4_private_addresses --
        #
      when /^10\.\d+\.\d+\.\d+$/                   then :private_24
      when /^172\.(?:1[6-9]|2\d|3[01])\.\d+\.\d+$/ then :private_20
      when /^192\.168\.\d+\.\d+$/                  then :private_16
      when /^33\.33\.\d+\.\d+$/                    then :host_only
      else :public
      end
    end

  end
end
