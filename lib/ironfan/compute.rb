require 'ironfan/volume'            # configure external and internal volumes
module Ironfan
  #
  # Base class allowing us to layer settings for facet over cluster
  #
  class ComputeBuilder < Ironfan::DslBuilder
    magic :name, String
    magic :bogosity, String, :default => false
    magic :environment, String
    collection :volumes, Ironfan::Volume, :resolution => ->(f) { merge_resolve(f) }

    attr_reader :cloud, :chef_roles
    @@role_implications ||= Mash.new
    @@run_list_rank     ||= 0

    def initialize(builder_name, attrs={})
      super(attrs)
      name      builder_name
      @run_list_info = attrs[:run_list] || Mash.new
      @clouds  = Mash.new
    end

    # set the bogosity to a descriptive reason. Anything truthy implies bogusness
    def bogus?
      !! self.bogosity
    end

    # Magic method to produce cloud instance:
    # * returns the cloud instance, creating it if necessary.
    # * executes the block in the cloud's object context
    #
    # @example
    #   cloud do
    #     image_name     'maverick'
    #     security_group :nagios
    #   end
    #
    #   # defines ec2-specific behavior
    #   cloud(:ec2) do
    #     public_ip      '1.2.3.4'
    #     region         'us-east-1d'
    #   end
    #
    def cloud(cloud_provider=:ec2, attrs={}, &block)
      case cloud_provider
      when :ec2
        klass = Ironfan::CloudDsl::Ec2
      when :virtualbox
        klass = Ironfan::CloudDsl::VirtualBox
      else
        raise "Only have EC2 and VirtualBox so far"
      end
      @clouds[cloud_provider] ||= klass.new(self)
      @clouds[cloud_provider].receive!(attrs, &block)
      @clouds[cloud_provider]
    end

    # sugar for cloud(:ec2)
    def ec2(attrs={}, &block)
      cloud(:ec2, attrs, &block)
    end

    def raid_group(rg_name, attrs={}, &block)
      raid = volumes[rg_name] || Ironfan::RaidGroup.new(:parent => self, :name => rg_name)
      raid.receive!(attrs, &block)
      raid.sub_volumes.each do |sv_name|
        volume(sv_name){ in_raid(rg_name) ; mountable(false) ; tags({}) }
      end
      volumes[rg_name] = raid
    end

    #
    # Adds the given role to the run list, and invokes any role_implications it
    # implies (for instance, defining and applying the 'ssh' security group if
    # the 'ssh' role is applied.)
    #
    # You can specify placement of `:first`, `:normal` (or nil) or `:last`; the
    # final runlist is assembled as
    #
    # * run_list :first  items -- cluster, then facet, then server
    # * run_list :normal items -- cluster, then facet, then server
    # * run_list :last   items -- cluster, then facet, then server
    #
    # (see Ironfan::Server#combined_run_list for full details though)
    #
    def role(role_name, placement=nil)
      add_to_run_list("role[#{role_name}]", placement)
      self.instance_eval(&@@role_implications[role_name]) if @@role_implications[role_name]
    end

    # Add the given recipe to the run list. You can specify placement of
    # `:first`, `:normal` (or nil) or `:last`; the final runlist is assembled as
    #
    # * run_list :first  items -- cluster, then facet, then server
    # * run_list :normal items -- cluster, then facet, then server
    # * run_list :last   items -- cluster, then facet, then server
    #
    # (see Ironfan::Server#combined_run_list for full details though)
    #
    def recipe(name, placement=nil)
      add_to_run_list(name, placement)
    end

    # Roles and recipes for this element only.
    #
    # See Ironfan::Server#combined_run_list for run_list order resolution
    def run_list
      groups = run_list_groups
      [ groups[:first], groups[:normal], groups[:last] ].flatten.compact.uniq
    end

    # run list elements grouped into :first, :normal and :last
    def run_list_groups
      @run_list_info.keys.sort_by{|item| @run_list_info[item][:rank] }.group_by{|item| @run_list_info[item][:placement] }
    end

    #
    # Some roles imply aspects of the machine that have to exist at creation.
    # For instance, on an ec2 machine you may wish the 'ssh' role to imply a
    # security group explicity opening port 22.
    #
    # @param [String] role_name -- the role that triggers the block
    # @yield block will be instance_eval'd in the object that calls 'role'
    #
    def self.role_implication(name, &block)
      @@role_implications[name] = block
    end

  protected

    def add_to_run_list(item, placement)
      raise "run_list placement must be one of :first, :normal, :last or nil (also means :normal)" unless [:first, :last, :own, nil].include?(placement)
      @@run_list_rank += 1
      placement ||= :normal
      @run_list_info[item] ||= { :rank => @@run_list_rank, :placement => placement }
    end

  end
end
