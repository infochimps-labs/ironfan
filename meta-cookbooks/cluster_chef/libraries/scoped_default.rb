module ClusterChef
  module CookbookUtils

    module ScopedLibraries
      def scoped_default(name, component, key, required=false)
        case
        when (component && node[name][component] && node[name][component][key])
          return node[name][component][key]
        when (node[name] && node[name][key])
          return node[name][key]
        when required
          Chef::Log.warn "daemon_user definition can't find default for #{key} in node[:#{name}][:#{component}] or node[:#{name}]"
          return nil
        end
      end
    end

  end
end


class Chef::ResourceDefinition ; include ClusterChef::CookbookUtils::ScopedLibraries ; end
class Chef::Resource           ; include ClusterChef::CookbookUtils::ScopedLibraries ; end
class Chef::Recipe             ; include ClusterChef::CookbookUtils::ScopedLibraries ; end
