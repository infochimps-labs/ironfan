#
# ~~ DO NOT EDIT ~~
#

unless defined?(Chef::Config)
  puts <<-EOL
    Warning!

    This might *look* like a vagrantfile.  However it's only useful when you use
    `knife cluster vm` to manipulate it.  Any changes you put here will be
    clobbered, and you can't edit the original if you install ironfan as a gem.
    Annoying, but concentrate on the magic of the jetpack-powered ridiculous
    cybernetic future magic that's going on here.

    Instead, issue commands like

        knife cluster vagrant COMMAND CLUSTER[-FACET-[INDEXES]]

    Where command is something like

        status up provision reload resume suspend ssh destroy or halt

EOL
  exit(2)
end


Vagrant::Config.run do |config|

  #
  # FIXME: the things in this first section need to go somewhere else; need to
  # learn more abt vagrant to figure out where.
  #

  def ip_for(svr)
    "#{Chef::Config.host_network_blk}.#{30 + svr.facet_index}"
  end

  # FIXME: things like this should be imputed by the `cloud` statement
  ram_mb           = 640

  # ===========================================================================
  #
  # Configure VM
  #

  # Boot with a GUI so you can see the screen. (Default is headless)
  config.vm.boot_mode = :gui

  # Mount this to see all our chefs and stuff: [type, vm_path, host_path]
  config.vm.share_folder "homebase", Chef::Config.homebase_on_vm_dir, Chef::Config.homebase

  #
  # Define a VM for all the targeted servers in the cluster.
  #
  # * vm name   - server's fullname ('el_ridiculoso-grande-2')
  # * vm box    - cloud.image_name
  # * creates host network on the subnet defined in Chef::Config[:host_network_blk]
  # * populates chef provisioner from the server's run_list
  #
  $ironfan_target.servers.each do |svr|
    config.vm.define svr.fullname.to_sym do |cfg|

      cfg.vm.box     = svr.cloud.image_name
      cfg.vm.network  :hostonly, ip_for(svr)

      #
      # See http://www.virtualbox.org/manual/ch08.html#idp12418752
      # for the craziness
      #
      vm_customizations = {
        "modifyvm" => :id,
        "--name"   => svr.fullname.to_s,
        # Use the host resolver for DNS so that VPN continues to work within the VM
        "--natdnshostresolver1" => "on",
      }
      # vm_customizations["--memory"] = svr.cloud.ram_mb.to_s if svr.cloud.ram_mb
      #
      cfg.vm.customize vm_customizations

      # Assign this VM to a bridged network, allowing you to connect directly to a
      # network using the host's network device. This makes the VM appear as another
      # physical device on your network.
      # cfg.vm.network :bridged

      # Forward a port from the guest to the host, which allows for outside
      # computers to access the VM, whereas host only networking does not.
      # cfg.vm.forward_port 80, 8080

      cfg.vm.provision Vagrant::Provisioners::IronfanChefClient do |chef|
        #
        chef.node_name              = svr.fullname

        chef.chef_server_url        = svr.chef_server_url
        chef.validation_client_name = svr.validation_client_name
        chef.validation_key_path    = svr.validation_key
        chef.upload_client_key      = svr.client_key.filename if svr.client_key

        chef.environment            = svr.environment
        chef.json                   = svr.cloud.user_data

        svr.combined_run_list.each do |run_list_entry|
          case run_list_entry
          when /^role\[(\w+)\]$/   then chef.add_role($1)                # role[foo]
          when /^recipe\[(\w+)\]$/ then chef.add_recipe($1)              # recipe[foo]
          else                          chef.add_recipe(run_list_entry)  # foo
          end
        end

      end
    end
  end

end
