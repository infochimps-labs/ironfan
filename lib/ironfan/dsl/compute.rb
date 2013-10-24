module Ironfan
  class Dsl

    class RunListItem < Hash
      Gorillib::Factory.register_factory(self, [self])
      def name
        self[:name]
      end
      def self.receive(hsh)
        new.merge!(hsh.symbolize_keys)
      end
    end

    class Compute < Ironfan::Dsl
      @@run_list_rank = 0
      field      :name,         String

      # Resolve each of the following as a merge of their container's attributes and theirs
      collection :components,   Ironfan::Dsl::Component,   :resolver => :merge_resolve, :key_method => :name
      collection :run_list_items, RunListItem,             :resolver => :merge_resolve, :key_method => :name
      collection :clouds,       Ironfan::Dsl::Cloud,       :resolver => :merge_resolve, :key_method => :name
      collection :volumes,      Ironfan::Dsl::Volume,      :resolver => :merge_resolve, :key_method => :name

      # Resolve these normally (overriding on each layer)
      magic      :environment,  Symbol,                    :default => :_default
      magic      :use_cloud,    Symbol

      member     :cluster_role, Ironfan::Dsl::Role
      member     :facet_role,   Ironfan::Dsl::Role

      magic      :cluster_names, Whatever
      magic      :realm_name,    Symbol

      def initialize(attrs={},&block)
        self.underlay   = attrs[:owner] if attrs[:owner]
        super
      end

      def full_name()   name;   end

      # Add the given role/recipe to the run list. You can specify placement of
      #   `:first`, `:normal` (or nil) or `:last`; the final runlist is assembled
      #   in order by placement, and then by source position.
      def role(role_name, placement=nil)
        add_to_run_list("role[#{role_name}]", placement)
      end
      def recipe(recipe_name, placement=nil)
        add_to_run_list(recipe_name, placement)
      end
      def run_list
        mapper = run_list_items.values.map
        result =  mapper.each {|i| i[:name] if i[:placement]==:first  }
        result += mapper.each {|i| i[:name] if i[:placement]==:normal }
        result += mapper.each {|i| i[:name] if i[:placement]==:last   }
        result.compact
      end

      def raid_group(rg_name, attrs={}, &block)
        raid = volumes[rg_name] || Ironfan::Dsl::RaidGroup.new(:name => rg_name)
        raid.receive!(attrs, &block)
        raid.sub_volumes.each do |sv_name|
          volume(sv_name){ in_raid(rg_name) ; mountable(false) ; tags({}) }
        end
        volumes[rg_name] = raid
      end

      # TODO: Expand the logic here to include CLI parameters, probably by injecting
      #   the CLI as a layer in the underlay structure
      def selected_cloud
        raise "No clouds defined, cannot select a cloud" if clouds.length == 0

        # Use the selected cloud for this server
        unless use_cloud.nil?
          return cloud(use_cloud) if clouds.include? use_cloud
          raise "Requested a cloud (#{use_cloud}) that is not defined"
        end

        # Use the cloud marked default_cloud
        default = clouds.values.select{|c| c.default_cloud == true }
        raise "More than one cloud (#{default.map{|c| c.name}.join(', ')}) marked default" if default.length > 1
        return default[0] unless default.empty?

        # Use the first cloud defined
        clouds.values.first
      end

    protected

      def add_to_run_list(item, placement=nil)
        raise "run_list placement must be one of :first, :normal, :last or nil (also means :normal)" unless [:first, :last, :own, nil].include?(placement)
        placement = :normal if placement.nil?
        @@run_list_rank += 1
        # Rank is a global order that tells what order this was encountered in. 
        run_list_items[item] = { :name => item, :rank => @@run_list_rank, :placement => placement }
      end
    end

  end
end
