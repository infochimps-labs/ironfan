require File.expand_path('metachef.rb', File.dirname(__FILE__))
module ClusterChef

  #
  # * scope[:run_state]
  #
  # from the eponymous service resource,
  # * service.path
  # * service.pattern
  # * service.user
  # * service.group
  #
  class DaemonAspect < Aspect
    register!
    dsl_attr(:service_name, :kind_of => String)
    dsl_attr(:pattern,      :kind_of => String)
    dsl_attr(:run_state,    :kind_of => [String, Symbol])
    dsl_attr(:service_name, :kind_of => String)

    def self.harvest(run_context, component)
      rsrc_matches(run_context.resource_collection, :service, component.sys) do |rsrc|
        next unless rsrc.name =~ /#{component.name}/
        svc = self.new(component, rsrc.name, rsrc.service_name, rsrc.pattern)
        svc.run_state(component.node_info[:run_state])
        svc
      end
    end

    def lint
      errs = super
      if  not %w[stop start nothing].include?(run_state.to_s)
        badness = run_state ? "Odd run_state #{run_state}" : "No run_state"
        err = "#{badness} for daemon #{name}: set node[:#{component.sys}][:#{component.subsys}] to :stop, :start or :nothing"
        Chef::Log.warn(err)
        errs << err
      end
      errs
    end
  end

  class PortAspect < Aspect
    register!
    dsl_attr(:flavor,    :kind_of => Symbol, :coerce => :to_sym)
    dsl_attr(:port_num,  :kind_of => String)
    dsl_attr(:addrs,     :kind_of => Array)

    ALLOWED_FLAVORS = [ :ssh, :ntp, :ldap, :smtp, :ftp, :http, :pop, :nntp, :imap, :tcp, :https, :telnet ]
    def self.allowed_flavors() ALLOWED_FLAVORS ; end

    def self.harvest(run_context, component)
      attr_aspects = attr_matches(component, /^((.+_)?port)$/) do |key, val, match|
        name   = match[1]
        flavor = match[2].to_s.empty? ? :port : match[2].gsub(/_$/, '').to_sym
        # p [match.captures, name, flavor].flatten
        self.new(component, name, flavor, val.to_s)
      end
    end
  end

  class DashboardAspect < Aspect
    register!
    dsl_attr(:flavor,    :kind_of => Symbol, :coerce => :to_sym)
    dsl_attr(:url,       :kind_of => String)

    ALLOWED_FLAVORS = [ :http, :jmx ]
    def self.allowed_flavors() ALLOWED_FLAVORS ; end

    def self.harvest(run_context, component)
      attr_aspects = attr_matches(component, /^(.*dash)_port(s)?$/) do |key, val, match|
        name   = match[1]
        flavor = (name == 'dash') ? :http_dash : name.to_sym
        url    = "http://#{private_ip_of(run_context.node)}:#{val}/"
        self.new(component, name, flavor, url)
      end
    end
  end

  #
  # * scope[:log_dirs]
  # * scope[:log_dir]
  # * flavor: http, etc
  #
  class LogAspect < Aspect
    register!
    dsl_attr(:flavor,    :kind_of => Symbol, :coerce => :to_sym)
    dsl_attr(:dirs,      :kind_of => Array)

    ALLOWED_FLAVORS = [ :http, :log4j, :rails ]

    def self.harvest(run_context, component)
      attr_matches(component, /^log_dir(s?)$/) do |key, val, match|
        name = 'log'
        dirs = Array(val)
        self.new(component, name, name.to_sym, dirs)
      end
    end
  end

  #
  # * attributes with a _dir or _dirs suffix
  #
  class DirectoryAspect < Aspect
    def self.plural_handle() :directories ; end
    register!
    dsl_attr(:flavor,    :kind_of => Symbol, :coerce => :to_sym)
    dsl_attr(:dirs,      :kind_of => Array)

    ALLOWED_FLAVORS = [ :home, :conf, :log, :tmp, :pid, :data, :lib, :journal, ]
    def self.allowed_flavors() ALLOWED_FLAVORS ; end

    def self.harvest(run_context, component)
      attr_aspects = attr_matches(component, /(.*)_dir(s?)$/) do |key, val, match|
        name = match[1]
        val  = Array(val)
        self.new(component, name, name.to_sym, val)
      end
      rsrc_aspects = rsrc_matches(run_context.resource_collection, :directory, component.sys) do |rsrc|
        rsrc
      end
      # [attr_aspects, rsrc_aspects].flatten.each{|x| p x }
      attr_aspects
    end
  end

  #
  # Code assets (jars, compiled libs, etc) that another system may wish to
  # incorporate
  #
  class ExportedAspect < Aspect
    register!
    dsl_attr(:flavor,    :kind_of => Symbol, :coerce => :to_sym)
    dsl_attr(:files,     :kind_of => Array)

    ALLOWED_FLAVORS = [:jars, :confs, :libs]
    def self.allowed_flavors() ALLOWED_FLAVORS ; end

    def lint
      super() + [lint_flavor]
    end

    def self.harvest(run_context, component)
      attr_matches(component, /^exported_(.*)$/) do |key, val, match|
        name = match[1]
        self.new(component, name, name.to_sym, val)
      end
    end
  end

  #
  # manana
  #

  # # usage constraints -- ulimits, java heap size, thread count, etc
  # class UsageLimitAspect
  # end
  # # deploy
  # # package
  # # account (user / group)
  # class CookbookAspect < Struct.new(:component, :name,
  #     :deploys, :packages, :users, :groups, :depends, :recommends, :supports,
  #     :attributes, :recipes, :resources, :authors, :license, :version )
  # end
  #
  # class CronAspect
  # end
  #
  # class AuthkeyAspect
  # end

end
