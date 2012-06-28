module Ironfan

  #
  # A server is a specific (logical) member of a facet within a cluster.
  #
  # It may have extra attributes if it also exists in the Chef server,
  # or if it exists in the real world (as revealed by Fog)
  #
  class Server < Ironfan::ComputeBuilder
    magic :cluster, Cluster
    magic :facet, Facet
    magic :facet_index, Integer
    attr_reader :tags

    magic :chef_node, Whatever, :default => -> owner,name { owner.cluster.find_node(name) || false }
    attr_accessor :fog_server

    @@all ||= Mash.new

    def initialize facet, idx
      cluster           facet.cluster
      facet             facet
      facet_index       idx
      @fullname    = [cluster_name, facet_name, facet_index].join('-')
      super(@fullname)
      @tags = { "name" => name, "cluster" => cluster_name, "facet"   => facet_name, "index" => facet_index, }
      ui.warn("Duplicate server #{[self, facet.name, idx]} vs #{@@all[fullname]}") if @@all[fullname]
      @@all[fullname] = self
    end

    def fullname fn=nil
      @fullname = fn if fn
      @fullname
    end

    def cluster_name
      cluster.name
    end

    def facet_name
      facet.name
    end

    def servers
      Ironfan::ServerSlice.new(cluster, [self])
    end

#     def bogosity val=nil
#       @settings[:bogosity] = val  if not val.nil?
#       return @settings[:bogosity] if not @settings[:bogosity].nil?
#       return :bogus_facet         if facet.bogus?
#       # return :out_of_range      if (self.facet_index.to_i >= facet.instances)
#       false
#     end

    def in_cloud?
      !! fog_server
    end

    def in_chef?
      chef_node || chef_client
    end

    def has_cloud_state?(*states)
      in_cloud? && states.flatten.include?(fog_server.state)
    end

    def exists?
      created? || in_chef?
    end

    def created?
      in_cloud? && (not ['terminated', 'shutting-down'].include?(fog_server.state))
    end

    def running?
      has_cloud_state?('running')
    end

    def startable?
      has_cloud_state?('stopped')
    end

    def launchable?
      not created?
    end

    def sshable?
      in_chef?
    end

    def permanent?
      [true, :true, 'true'].include?(self.cloud.permanent)
    end

    def killable?
      return false if permanent?
      in_chef? || created?
    end

    def to_s
      super[0..-3] + " chef: #{in_chef? && chef_node.name} fog: #{in_cloud? && fog_server.id}}>"
    end

    #
    # Attributes
    #

    def tag key, value=nil
      if value then @tags[key] = value ; end
      @tags[key]
    end

    def public_hostname
      give_me_a_hostname_from_one_of_these_seven_ways_you_assholes
    end

    def chef_server_url()        Chef::Config.chef_server_url        ; end
    def validation_client_name() Chef::Config.validation_client_name ; end
    def validation_key()         Chef::Config.validation_key         ; end
    def organization()           Chef::Config.organization           ; end
    #
    # Resolve:
    #
    def resolve!
      facet.underlay            cluster
      self.underlay             facet.cloud

      #@settings[:run_list] = combined_run_list

      facet.cloud.underlay      cluster.cloud
      cloud.underlay            facet.cloud

      cloud.user_data({
          :chef_server            => chef_server_url,
          :validation_client_name => validation_client_name,
          #
          :node_name              => fullname,
          :organization           => organization,
          :cluster_name           => cluster_name,
          :facet_name             => facet_name,
          :facet_index            => facet_index,
          #
          :run_list               => combined_run_list,
        })
      #
      cloud.keypair(cluster_name) if cloud.keypair.nil?
      #
      self
    end

    #
    # Assembles the combined runlist.
    #
    # * run_list :first  items -- cluster then facet then server
    # * run_list :normal items -- cluster then facet then server
    # * own roles: cluster_role then facet_role
    # * run_list :last   items -- cluster then facet then server
    #
    #    Ironfan.cluster(:my_cluster) do
    #      role('f',  :last)
    #      role('c')
    #      facet(:my_facet) do
    #        role('d')
    #        role('e')
    #        role('b', :first)
    #        role('h',  :last)
    #      end
    #      role('a', :first)
    #      role('g', :last)
    #    end
    #
    # produces
    #    cluster list  [a] [c]  [cluster_role] [fg]
    #    facet list    [b] [de] [facet_role]   [h]
    #
    # yielding run_list
    #     ['a', 'b', 'c', 'd', 'e', 'cr', 'fr', 'f', 'g', 'h']
    #
    # Avoid duplicate conflicting declarations. If you say define things more
    # than once, the *earliest encountered* one wins, even if it is elsewhere
    # marked :last.
    #
    def combined_run_list
      cg = @cluster.run_list_groups
      fg = @facet.run_list_groups
      sg = self.run_list_groups
      [ cg[:first],  fg[:first],  sg[:first],
        cg[:normal], fg[:normal], sg[:normal],
        cg[:own],    fg[:own],
        cg[:last],   fg[:last],   sg[:last], ].flatten.compact.uniq
    end

    #
    # This prepares a composited view of the volumes -- it shows the cluster
    # definition overlaid by the facet definition overlaid by the server
    # definition.
    #
    # This method *does* auto-vivify an empty volume declaration on the server,
    # but doesn't modify it.
    #
    # This code is pretty smelly, but so is the resolve! behavior. advice welcome.
    #
    def composite_volumes
      vols = {}
      facet.volumes.each do |vol_name, vol|
        self.volumes[vol_name] ||= Ironfan::Volume.new(:parent => self, :name => vol_name)
        vols[vol_name]         ||= self.volumes[vol_name].dup
        vols[vol_name].reverse_merge!(vol)
      end
      cluster.volumes.each do |vol_name, vol|
        self.volumes[vol_name] ||= Ironfan::Volume.new(:parent => self, :name => vol_name)
        vols[vol_name]         ||= self.volumes[vol_name].dup
        vols[vol_name].reverse_merge!(vol)
      end
      vols.each{|vol_name, vol| vol.availability_zone self.default_availability_zone }
      vols
    end

    # FIXME -- this will break on some edge case wehre a bogus node is
    # discovered after everything is resolve!d
    def default_availability_zone
      cloud.default_availability_zone
    end

    #
    # retrieval
    #
    def self.get(cluster_name, facet_name, facet_index)
      cluster = Ironfan.cluster(cluster_name)
      had_facet = cluster.has_facet?(facet_name)
      facet = cluster.facet(facet_name)
      facet.bogosity true unless had_facet
      had_server = facet.has_server?( facet_index )
      server = facet.server(facet_index)
      server.bogosity :not_defined_in_facet unless had_server
      return server
    end

    def self.all
      @@all
    end

    #
    # Actions!
    #

    def sync_to_cloud
      step "Syncing to cloud"
      attach_volumes
      create_tags
      associate_public_ip
      ensure_placement_group
      set_instance_attributes
    end

    def sync_to_chef
      step "Syncing to chef server"
      sync_chef_node
      true
    end

    # FIXME: a lot of AWS logic in here. This probably lives in the facet.cloud
    # but for the one or two things that come from the facet
    def create_server
      return nil if created? # only create a server if it does not already exist
      fog_create_server
    end

    def create_tags
      return unless created?
      step("  labeling servers and volumes")
      fog_create_tags(fog_server, self.fullname, tags)
      composite_volumes.each do |vol_name, vol|
        if vol.fog_volume
          fog_create_tags(vol.fog_volume, vol.desc,
            { "server" => self.fullname, "name" => "#{name}-#{vol.name}", "device" => vol.device, "mount_point" => vol.mount_point, "cluster" => cluster_name, "facet"   => facet_name, "index"   => facet_index, })
        end
      end
    end

    def block_device_mapping
      composite_volumes.values.map(&:block_device_mapping).compact
    end

    # ugh. non-dry below.

    def announce_as_started
      return unless chef_node
      announce_state('start')
      chef_node.save
    end

    def announce_as_stopped
      return unless chef_node
      announce_state('stop')
      chef_node.save
    end

  protected

    def give_me_a_hostname_from_one_of_these_seven_ways_you_assholes
      # note: there are not actually seven ways. That is the least absurd part of this situation.
      case
      when cloud.public_ip
        cloud.public_ip
      when fog_server && fog_server.respond_to?(:public_ip_address) && fog_server.public_ip_address.present?
        fog_server.public_ip_address
      when fog_server && fog_server.respond_to?(:ipaddress)
        fog_server.ipaddress
      when fog_server && fog_server.respond_to?(:dns_name)
        fog_server.dns_name
      else
        nil
      end
    end

  end
end
