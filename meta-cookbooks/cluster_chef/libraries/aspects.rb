require File.expand_path('cluster_chef.rb', File.dirname(__FILE__))
module ClusterChef
  [:DaemonAspect, :LogAspect, :DirectoryAspect, :DashboardAspect, :PortAspect, :ExportedAspect,
  ].each{|klass| self.send(:remove_const, klass) rescue nil }

  #
  # * scope[:run_state]
  #
  # from the eponymous service resource,
  # * service.path
  # * service.pattern
  # * service.user
  # * service.group
  #
  class DaemonAspect < Struct.new(:name,
      :pattern,    # pattern to detect process
      :run_state ) # desired run state
    include Aspect; register!

    def self.harvest(run_context, sys, subsys, info)
      rsrc_matches(run_context.resource_collection, :service, sys) do |rsrc|
        next unless rsrc.name =~ /#{sys}_#{subsys}/
        svc = self.new(rsrc.name, rsrc.pattern)
        svc.run_state = info[:run_state].to_s if info[:run_state]
        svc
      end
    end
  end

  class PortAspect < Struct.new(:name,
      :flavor,
      :port_num,
      :addrs)
    include Aspect; register!
    ALLOWED_FLAVORS = [:http, :https, :pop3, :imap, :ftp, :jmx, :ssh, :nntp, :udp, :selfsame]
    def self.allowed_flavors() ALLOWED_FLAVORS ; end

    def self.harvest(run_context, sys, subsys, info)
      attr_aspects = attr_matches(info, /^((.+_)?port)$/) do |key, val, match|
        name   = match[1]
        flavor = match[2].to_s.empty? ? :port : match[2].gsub(/_$/, '').to_sym
        # p [match.captures, name, flavor].flatten
        self.new(name, flavor, val.to_s)
      end
    end
  end

  class DashboardAspect < Struct.new(:name, :flavor,
      :url)
    include Aspect; register!
    ALLOWED_FLAVORS = [ :http, :jmx ]
    def self.allowed_flavors() ALLOWED_FLAVORS ; end

    def self.harvest(run_context, sys, subsys, info)
      attr_aspects = attr_matches(info, /^(.*dash)_port(s)?$/) do |key, val, match|
        name   = match[1]
        flavor = (name == 'dash') ? :http_dash : name.to_sym
        url    = "http://#{private_ip_of(run_context.node)}:#{val}/"
        self.new(name, flavor, url)
      end
    end
  end

  #
  # * scope[:log_dirs]
  # * scope[:log_dir]
  # * flavor: http, etc
  #
  class LogAspect < Struct.new(:name,
      :flavor,
      :dirs )
    include Aspect; register!
    ALLOWED_FLAVORS = [ :http, :log4j, :rails ]

    def self.harvest(run_context, sys, subsys, info)
      attr_matches(info, /^log_dir(s?)$/) do |key, val, match|
        name = 'log'
        self.new(name, name.to_sym, val)
      end
    end
  end

  #
  # * attributes with a _dir or _dirs suffix
  #
  class DirectoryAspect < Struct.new(:name,
      :flavor,  # log, conf, home, ...
      :dirs    # directories pointed to
      )
    include Aspect; register!
    ALLOWED_FLAVORS = [ :home, :conf, :log, :tmp, :pid, :data, :lib, :journal, ]
    def self.allowed_flavors() ALLOWED_FLAVORS ; end

    def self.harvest(run_context, sys, subsys, info)
      attr_aspects = attr_matches(info, /(.*)_dir(s?)$/) do |key, val, match|
        name = match[1]
        self.new(name, name.to_sym, val)
      end
      rsrc_aspects = rsrc_matches(run_context.resource_collection, :directory, sys) do |rsrc|
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
  class ExportedAspect < Struct.new(:name,
      :flavor,
      :files)
    include Aspect; register!

    ALLOWED_FLAVORS = [:jars, :confs, :libs]
    def self.allowed_flavors() ALLOWED_FLAVORS ; end

    def flavor=(val)
      val = val.to_sym unless val.nil?
      super(val)
    end

    def lint
      errors  = []
      errors += lint_flavor
      errors + super()
    end

    def self.harvest(run_context, sys, subsys, info)
      attr_matches(info, /^exported_(.*)$/) do |key, val, match|
        name = match[1]
        self.new(name, name.to_sym, val)
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
  # class CookbookAspect < Struct.new( :name,
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
