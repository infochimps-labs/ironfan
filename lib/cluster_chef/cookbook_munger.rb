#!/usr/bin/env ruby

require 'configliere'
require 'extlib/mash'
require 'gorillib/metaprogramming/class_attribute'
require 'gorillib/hash/reverse_merge'
require 'gorillib/object/blank'
require 'gorillib/hash/compact'
require 'set'

require 'erubis'
require 'chef/mixin/from_file'

$:.unshift File.expand_path('..', File.dirname(__FILE__))
require 'cluster_chef/dsl_object'


Settings.define :maintainer,       :default => "Philip (flip) Kromer - Infochimps, Inc"
Settings.define :maintainer_email, :default => "coders@infochimps.com"
Settings.define :license,          :default => "Apache 2.0"
Settings.define :long_desc_gen,    :default => %Q{IO.read(File.join(File.dirname(__FILE__), 'README.md'))}
Settings.define :version,          :default => "3.0.0"

module CookbookMunger
  TEMPLATE_ROOT  = File.expand_path('cookbook_munger', File.dirname(__FILE__))
  COOKBOOKS_ROOT = File.expand_path('../..', File.dirname(__FILE__))

  class DummyAttribute
    attr_accessor :name
    attr_accessor :display_name
    attr_accessor :description
    attr_accessor :choice
    attr_accessor :calculated
    attr_accessor :type
    attr_accessor :required
    attr_accessor :recipes
    attr_accessor :default

    def initialize(name, hsh={})
      self.name = name
      merge!(hsh)
      @display_name ||= ''
      @description  ||= ''
    end

    def merge!(hsh)
      hsh.each do |key, val|
        self.send("#{key}=", val) unless val.blank?
      end
    end

    def inspect
      "attr[#{name}:#{default.inspect}]"
    end

    def bracketed_name
      name.split("/").map{|s| "[:#{s}]" }.join
    end

    def keys
      [:display_name, :description, :choice, :calculated, :type, :required, :recipes, :default]
    end

    def to_hash
      hsh = {}
      keys.each do |key|
        hsh[key] = self.send(key) if instance_variable_defined?("@#{key}")
      end
      case hsh[:default]
      when Symbol, Numeric, TrueClass, NilClass, FalseClass then hsh[:default] = hsh[:default].to_s
      when Hash            then hsh[:type] ||= 'hash'
      when Array           then hsh[:type] ||= 'array'
      end
      hsh
    end

    def pretty_str
      str = [ %Q{attribute "#{name}"} ]
      to_hash.each do |key, val|
        str << ("  :%-21s => %s" % [ key, val.inspect ])
      end
      str.flatten.join(",\n")
    end

  end

  class DummyAttributeCollection < Mash
    attr_accessor :path

    def initialize(path='')
      self.path = path
      super(){|hsh,key| hsh[key] = DummyAttributeCollection.new(sub_path(key)) }
    end

    def setter(key=nil)
      # key ? (self[key] = DummyAttributeCollection.new(sub_path(key))) : self
      self
    end

    def sub_path(key)
      path.blank? ? key.to_s : "#{path}/#{key}"
    end

    def []=(key, val)
      unless val.is_a?(DummyAttributeCollection) || val.is_a?(DummyAttribute)
        val = DummyAttribute.new(sub_path(key), :default =>val)
      end
      super(key, val)
    end

    def attrs
      [ leafs.values, branches.map{|key,val| val.attrs } ].flatten
    end

    def leafs
      select{|key,val| not val.is_a?(DummyAttributeCollection) }
    end
    def branches
      select{|key,val|     val.is_a?(DummyAttributeCollection) }
    end

    def pretty_str
      str = []
      attrs.each{|attrib| str << attrib.pretty_str }
      str.join("\n\n")
    end

  end

  module CookbookComponent
    attr_reader :filename

    def initialize(filename, *args, &block)
      super(*args, &block)
      @filename = filename
    end

    def read!
      from_file(filename)
    end

    module ClassMethods
      def read(filename)
        attr_file = self.new(filename)
        attr_file.read!
        attr_file
      end
    end
    def self.included(base) base.extend ClassMethods ; end
  end

  class RecipeFile
    include       CookbookComponent

  end

  class AttributeFile
    include       Chef::Mixin::FromFile
    include       CookbookComponent
    attr_reader   :all_attributes

    def initialize(filename)
      super(filename)
      @all_attributes = DummyAttributeCollection.new
    end

    def default
      all_attributes
    end
    def set
      all_attributes
    end
    def node
      { :platform     => 'ubuntu',   :platform_version => '10.4',
        :hostname     => 'hostname',
        :cpu          => {:total => 2 }, :memory => { :total => 2 },
        :kernel       => {:os => '', :release => '', :machine => '' ,},
        :cluster_name => :cluster_name,
        :ec2          => { :instance_type => 'm1.large', },
        :jenkins      => { :server => { :user => 'jenkins' } },
        :redis        => { :slave => 'no' },
        :cloud        => { :private_ips => ['10.20.30.40'] }
      }
    end

  end

  class CookbookMetadata < ClusterChef::DslObject
    include       Chef::Mixin::FromFile
    attr_reader   :cookbook_type
    has_keys      :name, :author, :maintainer, :maintainer_email, :license, :version, :description, :long_desc_gen
    attr_reader   :all_depends, :all_recipes, :all_attributes, :all_resources, :all_supports
    attr_reader   :components, :attribute_files

    # also: grouping, conflicts, provides, replaces, recommends, suggests

    # definition: provides "here(:kitty, :time_to_eat)"
    # resource:   provides "service[snuggle]"

    def initialize(cookbook_type, nm, *args, &block)
      super(*args, &block)
      name(nm)
      @cookbook_type    = cookbook_type
      @attribute_files  = {}
      @all_attributes   = CookbookMunger::DummyAttributeCollection.new
      @all_depends    ||= {}
      @all_recipes    ||= {}
      @all_resources  ||= {}
      @all_supports   ||= %w[ debian ubuntu ]
    end

    #
    # Fake DSL
    #

    # add dependency to list
    def depends(nm, ver=nil)  @all_depends[nm] = (ver ? %Q{"#{nm}", "#{ver}"} : %Q{"#{nm}"} ) ; end
    # add supported OS to list
    def supports(nm)          @all_supports << nm ; @all_supports.uniq! ; @all_supports ; end
    # add recipe to list
    def recipe(nm, desc)      @all_recipes[nm]   = { :name => nm, :description => desc } ;   end
    # add resource to list
    def resource(nm, desc)    @all_resources[nm] = { :name => nm, :description => desc } ;   end
    # fake long description -- we ignore it anyway
    def long_description(val) @long_description = val end

    # add attribute to list
    def attribute(nm, info={})
      path_segs = nm.split("/")
      leaf      = path_segs.pop
      attr_branch = @all_attributes
      path_segs.each{|seg| attr_branch = attr_branch[seg] }
      if info.present? || (not attr_branch.has_key?(leaf))
        attr_branch[leaf] = CookbookMunger::DummyAttribute.new(nm, info)
      end
      attr_branch[leaf]
    end

    #
    # Read project
    #

    def file_in_cookbook(filename)
      File.expand_path("#{cookbook_type}-cookbooks/#{name}/#{filename}", CookbookMunger::COOKBOOKS_ROOT)
    end

    def load_components
      from_file(file_in_cookbook("metadata.rb"))

      @components = {
        :attributes  => Dir[file_in_cookbook('attributes/*.rb')   ].map{|f| File.basename(f, '.rb') },
        :recipes     => Dir[file_in_cookbook('recipes/*.rb')      ].map{|f| File.basename(f, '.rb') },
        :resources   => Dir[file_in_cookbook('resources/*.rb')    ].map{|f| File.basename(f, '.rb') },
        :providers   => Dir[file_in_cookbook('providers/*.rb')    ].map{|f| File.basename(f, '.rb') },
        :templates   => Dir[file_in_cookbook('templates/**/*.rb') ].map{|f| File.join(File.basename(File.dirname(f)), File.basename(f, '.rb')) },
        :definitions => Dir[file_in_cookbook('definitions/*.rb')  ].map{|f| File.basename(f, '.rb') },
        :libraries   => Dir[file_in_cookbook('definitions/*.rb')  ].map{|f| File.basename(f, '.rb') },
      }

      components[:attributes].each{|attrib_name| add_attribute_file(attrib_name) }
    end

    def add_attribute_file(attrib_name)
      attr_file = AttributeFile.read(file_in_cookbook("attributes/#{attrib_name}.rb"))
      self.attribute_files[attrib_name] = attr_file
      attr_file.all_attributes.attrs.each do |af_attrib|
        my_attrib = attribute(af_attrib.name)
        my_attrib.merge!(af_attrib.to_hash)
        p [my_attrib, af_attrib]
      end
      # puts af.all_attributes.pretty_str
      attr_file
    end

    def lint!
      # Settings.each do |attr, sval|
      #   my_val = self.send(attr) rescue nil
      #   warn([name, attr, sval, my_val ]) unless sval == my_val
      # end
    end

    def dump
      load_components

      lint!

      File.open(file_in_cookbook('metadata.rb.bak'), 'w') do |f|
        f << render('metadata.rb')
      end
    end

    #
    # Content
    #

    def self.licenses
      return @licenses if @licenses
      @licenses = YAML.load(self.load_template_file('licenses.yaml'))
    end

    def license_info
      return @license_info if @license_info.nil?
      @license_info = self.class.licenses.values.detect{|lic| lic[:name] == license } || false
    end

    def short_license_text
      license_info ? license_info[:short] : '(no license specified)'
    end

    def copyright_text
      "2011, #{maintainer}"
    end

    #
    # Display
    #

    def render(filename)
      self.class.template(filename).result(self.send(:binding))
    end

    def self.template(filename)
      template_text = File.read(File.expand_path("#{filename}.erb", CookbookMunger::TEMPLATE_ROOT))
      Erubis::Eruby.new(template_text)
    end
  end

  [:meta, :site].each do |cookbook_type|
    Dir[CookbookMunger::COOKBOOKS_ROOT+"/#{cookbook_type}-cookbooks/*/metadata.rb"].map{|f| File.basename(File.dirname(f)) }.each do |nm|
      puts nm
      cookbook_metadata = CookbookMetadata.new(cookbook_type, nm, Settings.dup)
      cookbook_metadata.dump
    end
  end

  # attr_file = CookbookMunger::AttributeFile.new(File.expand_path('site-pig/attributes/default.rb', CookbookMunger::COOKBOOKS_ROOT))
  # attr_file.read!
  # puts attr_file.all_attributes.pretty_str

  # p cookbook_metadata.all_attributes
  # puts Time.now
end
