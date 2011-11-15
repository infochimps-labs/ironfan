#!/usr/bin/env ruby

#
# cookbook_munger.rb -- keep cookbook metadata complete, consistent and correct.
#
# This script reads the actual content of a cookbook -- actually interpreting
# the metadata.rb and attribute files, along with recipes/resources/etc files'
# headers -- and re-generates the metadata.rb and README files.
#
# It also has hooks to do a limited amount of validation and linting.
#

require 'configliere'
require 'extlib/mash'
require 'gorillib/metaprogramming/class_attribute'
require 'gorillib/hash/reverse_merge'
require 'gorillib/object/blank'
require 'gorillib/hash/compact'
require 'gorillib/string/inflections'
require 'gorillib/string/human'
require 'set'

require 'erubis'
require 'chef/mixin/from_file'

$:.unshift File.expand_path('..', File.dirname(__FILE__))
require 'cluster_chef/dsl_object'

Settings.define :maintainer,       :default => 'default mantainer name', :default => "Philip (flip) Kromer - Infochimps, Inc"
Settings.define :maintainer_email, :default => 'default email to add to cookbook headers', :default => "coders@infochimps.com"
Settings.define :license,          :default => 'default license to apply to cookbooks', :default => "Apache 2.0"
#
Settings.define :cookbook_paths,   :description => 'list of paths holding cookbooks', :type => Array, :default => ["./{site-cookbooks,meta-cookbooks}"]
#
Settings.use(:commandline)
Settings.resolve!

module CookbookMunger
  TEMPLATE_ROOT  = File.expand_path('cookbook_munger', File.dirname(__FILE__))

  # ===========================================================================
  #
  # DummyAttribute -- holds metadata about a single cookbook attribute.
  #
  # named like a path: node[:pig][:home_dir] is 'pig/home_dir'
  #
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

  # ===========================================================================
  #
  # DummyAttributeCollection -- the cascading buckets to hold attributes
  #
  # This auto-vivifies: just saying `foo[:bar][:baz][:bing]` results in
  # foo becoming
  #     `{ :bar => { :baz => { :bing => {} } } }`
  #
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

  # ===========================================================================
  #
  # CookbookComponent - shared mixin methods for Chef-DSL files (recipes,
  #   attributes, definitions, resources, etc)
  #
  module CookbookComponent
    attr_reader   :name, :desc, :filename
    # the cookbook object this belongs to
    attr_reader   :cookbook
    attr_accessor :header_lines, :body_lines

    def initialize(cookbook, name, desc, filename, *args, &block)
      super(*args, &block)
      @cookbook = cookbook
      @name     = name
      @desc     = desc
      @filename = filename
    end

    def raw_lines
      begin
        @raw_lines ||= File.readlines(filename).map(&:chomp)
      rescue Errno::ENOENT => boom
        warn boom.to_s
        return []
      end
    end

    def read
      @header_lines = []
      @body_lines   = []
      # Gobble the header -- all comment lines following the first
      until raw_lines.first !~ /^#/ || raw_lines.empty?
        line = raw_lines.first
        header_lines << raw_lines.shift
        process_header_line(line)
      end
      # skip blank lines that follow the header
      until raw_lines.first =~ /\S+/ || raw_lines.empty?
        raw_lines.shift
      end
      raw_lines.each do |line|
        body_lines << line
        process_body_line(line)
      end
    end

    # called on each header line in #read
    def process_header_line(line)
      # override in subclass if you like
    end
    # called on each body line in #read
    def process_body_line(line)
      # override in subclass if you like
    end

    # save to {filename}.bak
    def dump
      File.open(filename+'.bak', 'w') do |f|
        f << header_lines.join("\n")
        f << "\n\n"
        f << body_lines.join("\n")
        f << "\n"
      end
    end

    # Use the chef from_file mixin -- instance_exec the file
    def execute!
      from_file(filename)
    end

    module ClassMethods
      def read(cookbook, name, desc, filename)
        attr_file = self.new(cookbook, name, desc, filename)
        attr_file.read
        attr_file
      end
    end
    def self.included(base) base.extend ClassMethods ; end
  end

  # ===========================================================================
  #
  # RecipeFile -- a chef recipe
  #
  class RecipeFile
    attr_accessor :copyright_lines, :author_lines, :include_recipes
    include       CookbookComponent

    def initialize(*args, &block)
      super
      @include_recipes = []
    end

    def process_header_line(line)
      self.author_lines    << "# Author::              #{$1}" if line =~ /^# Author::\s*(.*)/
      self.copyright_lines << line if line =~ /^# Copyright / && line !~ /YOUR_COMPANY_NAME/
    end

    def process_body_line(line)
      if line =~ /include_recipe\(?\s*[\"\']([^\"\'\:]*?)(::.*?)?[\"\']\s*\)?(?:#.*)?$/
        self.include_recipes << $1
      end
    end

    def read
      self.author_lines      = []
      self.copyright_lines   = []
      super
      self.copyright_lines   = ["# Copyright #{cookbook.copyright_text}"]         if copyright_lines.blank?
      self.author_lines      = ["# Author::              #{cookbook.maintainer}"] if author_lines.blank?
    end

    def dump
      super
    end

    def generate_header!
      new_header_lines = ['#']
      new_header_lines << "# Cookbook Name::       #{cookbook.name}"
      new_header_lines << "# Description::         #{desc}"
      new_header_lines << "# Recipe::              #{name}"
      new_header_lines += author_lines
      new_header_lines << "#"
      new_header_lines += copyright_lines
      new_header_lines << "#"
      new_header_lines << ("# "+cookbook.short_license_text.gsub(/\n/, "\n# ").gsub(/\n# \n/, "\n#\n")) << '#'
      self.header_lines = new_header_lines
    end

  end

  # ===========================================================================
  #
  # AttributeFile -- a chef attribute file
  #
  # The metadata in here will be merged with anything found in the metadata.rb
  # file, with these winning
  #
  class AttributeFile
    include       Chef::Mixin::FromFile
    include       CookbookComponent
    attr_reader   :all_attributes

    def initialize(*args, &block)
      super(*args, &block)
      @all_attributes = DummyAttributeCollection.new
    end

    #
    # Fake the DSL so we can run the attributes file in our context
    #

    def default
      all_attributes
    end
    def set
      all_attributes
    end
    def attribute?(key) node.has_key?(key.to_sym) ; end
    def node
      { :platform     => 'ubuntu',   :platform_version => '10.4',
        :hostname     => 'hostname',
        :cpu          => {:total => 2 }, :memory => { :total => 2 },
        :kernel       => {:os => '', :release => '', :machine => '' ,},
        :cluster_name => :cluster_name,
        :ec2          => { :instance_type => 'm1.large', },
        :jenkins      => { :server => { :user => 'jenkins' } },
        :redis        => { :slave => 'no' },
        :cloud        => { :private_ips => ['10.20.30.40'] },
        :ipaddress    => '10.20.30.40',
      }.merge(@all_attributes)
    end
    def method_missing(meth, *args)
      if args.empty? && node.has_key?(meth)
        node[meth]
      else
        super(meth, *args)
      end
    end

  end

  # ===========================================================================
  #
  # CookbookMetadata -- the main deal. Unifies information from metadata.rb, the
  # attributes/ files, the rest of the tree; produces a synthesized metadata.rb
  # and README.md.
  #
  class CookbookMetadata < ClusterChef::DslObject
    include       Chef::Mixin::FromFile
    attr_reader   :dirname
    has_keys      :name, :author, :maintainer, :maintainer_email, :license, :version, :description, :long_desc_gen
    attr_reader   :all_depends, :all_recipes, :all_attributes, :all_resources, :all_supports, :all_recommends
    attr_reader   :components, :attribute_files

    # also: grouping, conflicts, provides, replaces, recommends, suggests

    # definition: provides "here(:kitty, :time_to_eat)"
    # resource:   provides "service[snuggle]"

    def initialize(nm, dirname, *args, &block)
      super(*args, &block)
      name(nm)
      @dirname          = dirname
      @attribute_files  = {}
      @all_attributes   = CookbookMunger::DummyAttributeCollection.new
      @all_depends    ||= {}
      @all_recommends ||= {}
      @all_supports   ||= %w[ debian ubuntu ]
      @all_recipes    ||= {}
      @all_resources  ||= {}
      long_desc_gen(%Q{IO.read(File.join(File.dirname(__FILE__), 'README.md'))}) unless long_desc_gen
    end

    #
    # Fake DSL
    #

    # add dependency to list
    def depends(nm, ver=nil)    @all_depends[nm]    = (ver ? %Q{"#{nm}", "#{ver}"} : %Q{"#{nm}"} ) ; end
    # add recommended dependency to list
    def recommends(nm, ver=nil) @all_recommends[nm] = (ver ? %Q{"#{nm}", "#{ver}"} : %Q{"#{nm}"} ) ; end
    # add supported OS to list
    def supports(nm, ver=nil)   @all_supports      << nm ; @all_supports.uniq!   ; @all_supports ; end
    # add resource to list
    def resource(nm, desc)      @all_resources[nm]  = { :name => nm, :description => desc } ;   end
    # fake long description -- we ignore it anyway
    def long_description(val)   @long_description = val end

    # add attribute to list
    def attribute(nm, info={})
      return if info[:type] == 'hash'
      path_segs = nm.split("/")
      leaf      = path_segs.pop
      attr_branch = @all_attributes
      path_segs.each{|seg| attr_branch = attr_branch[seg] }
      if info.present? || (not attr_branch.has_key?(leaf))
        attr_branch[leaf] = CookbookMunger::DummyAttribute.new(nm, info)
      end
      attr_branch[leaf]
    end

    # add recipe to list
    def recipe(recipe_name, desc=nil)
      recipe_name = 'default' if recipe_name == name
      recipe_name = recipe_name.gsub(/^#{name}::/, "")
      #
      desc        = (recipe_name == 'default' ? "Base configuration for #{name}" : recipe_name.titleize) if (desc.blank? || desc == recipe_name.titleize)
      filename    = file_in_cookbook("recipes/#{recipe_name}.rb")
      @all_recipes[recipe_name]      ||= RecipeFile.read(self, recipe_name, desc, filename)
      @all_recipes[recipe_name].desc ||= desc if desc.present?
      @all_recipes[recipe_name]
    end

    #
    # Read project
    #

    def file_in_cookbook(filename)
      File.expand_path(filename, self.dirname)
    end

    def load_components
      from_file(file_in_cookbook("metadata.rb"))

      @components = {
        :attributes  => Dir[file_in_cookbook('attributes/*.rb')   ].map{|f| nm = File.basename(f, '.rb') ; AttributeFile.read(self, nm, "attributes[#{self.name}::#{nm}", f) },
        :recipes     => Dir[file_in_cookbook('recipes/*.rb')      ].map{|f| nm = File.basename(f, '.rb') ; recipe("#{name}::#{nm}") },
        :resources   => Dir[file_in_cookbook('resources/*.rb')    ].map{|f| File.basename(f, '.rb') },
        :providers   => Dir[file_in_cookbook('providers/*.rb')    ].map{|f| File.basename(f, '.rb') },
        :templates   => Dir[file_in_cookbook('templates/**/*.rb') ].map{|f| File.join(File.basename(File.dirname(f)), File.basename(f, '.rb')) },
        :definitions => Dir[file_in_cookbook('definitions/*.rb')  ].map{|f| File.basename(f, '.rb') },
        :libraries   => Dir[file_in_cookbook('definitions/*.rb')  ].map{|f| File.basename(f, '.rb') },
      }

      components[:attributes].each do |attrib_file|
        merge_attribute_file(attrib_file)
      end
    end

    def merge_attribute_file(attrib_file)
      attrib_file.execute!
      attrib_file.all_attributes.attrs.each do |af_attrib|
        my_attrib = attribute(af_attrib.name)
        my_attrib.merge!(af_attrib.to_hash)
      end
    end

    def lint!
      # Settings.each do |attr, sval|
      #   my_val = self.send(attr) rescue nil
      #   warn([name, attr, sval, my_val ]) unless sval == my_val
      # end
      lint_dependencies
    end

    def lint_dependencies
      include_recipes = []
      components[:recipes].each do |recipe_file|
        include_recipes += recipe_file.include_recipes
      end
      include_recipes = include_recipes.sort.uniq
      missing_dependencies = (include_recipes  - all_depends.keys - [name])
      missing_includes     = (all_depends.keys - include_recipes  - [name, 'provides_service', 'install_from'])
      warn "Coookbook #{name} doesn't declare dependency on #{missing_dependencies.join(", ")}, but has an include_recipe that refers to it" if missing_dependencies.present?
      warn "Coookbook #{name} declares dependency on #{missing_includes.join(", ")}, but never calls include_recipe with it"             if missing_includes.present?
    end

    def dump
      load_components
      lint!
      File.open(file_in_cookbook('metadata.rb.bak'), 'w') do |f|
        f << render('metadata.rb')
      end
      components[:recipes].each do |recipe_file|
        recipe_file.generate_header!
        recipe_file.dump
      end
    end

    #
    # Content
    #

    def self.licenses
      return @licenses if @licenses
      @licenses = YAML.load(File.read(File.expand_path("licenses.yaml", CookbookMunger::TEMPLATE_ROOT)))
    end

    def license_info
      @license_info = self.class.licenses.values.detect{|lic| lic[:name] == license }
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

  Settings.cookbook_paths.each do |cookbook_path|
    Dir["#{cookbook_path}/*/metadata.rb"].each do |f|
      dirname = File.dirname(f)
      nm      = File.basename(dirname)
      puts "====== %-20s ====================" % nm
      cookbook_metadata = CookbookMetadata.new(nm, dirname, Settings.dup)
      cookbook_metadata.dump
    end
  end

end
