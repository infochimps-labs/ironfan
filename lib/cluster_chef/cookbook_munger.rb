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

require 'erubis'
require 'chef/mash'
require 'chef/mixin/from_file'

require 'configliere'
require 'gorillib/metaprogramming/class_attribute'
require 'gorillib/hash/reverse_merge'
require 'gorillib/object/blank'
require 'gorillib/hash/compact'
require 'gorillib/string/inflections'
require 'gorillib/string/human'
require 'gorillib/logger/log'
require 'set'

$:.unshift File.expand_path('..', File.dirname(__FILE__))
require 'cluster_chef/dsl_object'

# silence the chef log
class Chef ; class Log ; def self.info(*args) ; end ; def self.debug(*args) ; end ; end ; end

Settings.define :maintainer,       :default => 'default mantainer name', :default => "Philip (flip) Kromer - Infochimps, Inc"
Settings.define :maintainer_email, :default => 'default email to add to cookbook headers', :default => "coders@infochimps.com"
Settings.define :license,          :default => 'default license to apply to cookbooks', :default => "Apache 2.0"
#
Settings.define :cookbook_paths,   :description => 'list of paths holding cookbooks', :type => Array, :default => ["./vendor/infochimps"]
#
Settings.use(:commandline)
Settings.resolve!

String.class_eval do
  def commentize
    self.gsub(/\n/, "\n# ").gsub(/\n# \n/, "\n#\n")
  end
end

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
    attr_accessor :seen

    def initialize(name, hsh={})
      self.name = name
      self.seen = []
      merge!(hsh)
      @display_name ||= ''
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
      self.description = display_name if description.blank?
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
        @raw_lines ||= []
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
    attr_accessor :copyright_lines, :author_lines, :include_recipes, :include_cookbooks
    include       CookbookComponent

    def initialize(*args, &block)
      super
      @include_recipes   = []
      @include_cookbooks = []
    end

    def process_header_line(line)
      self.author_lines    << "# Author::              #{$1}" if line =~ /^# Author::\s*(.*)/
      self.copyright_lines << line if line =~ /^# Copyright / && line !~ /YOUR_COMPANY_NAME/
    end

    def process_body_line(line)
      if line =~ /include_recipe\(?\s*[\"\']([^\"\'\:]*?)(::.*?)?[\"\']\s*\)?(?:[#;].*)?$/
        i_cb, i_rp = [$1, $2]
        i_rp = nil if i_rp == "default"
        self.include_cookbooks << i_cb
        self.include_recipes   << [i_cb, i_rp].compact.join("::")
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

    def lint
      if self.name == 'default'
        sketchy = (include_recipes & %w[ runit::default java::sun ])
        if sketchy.present? then warn "Recipe #{cookbook.name}::#{name} includes #{sketchy.inspect} -- put these in component cookbooks, not the default." ; end
      end
    end

    def generate_header!
      new_header_lines = ['#']
      new_header_lines << "# Cookbook Name::       #{cookbook.name}"
      new_header_lines << "# Description::         #{desc.commentize}"
      new_header_lines << "# Recipe::              #{name}"
      new_header_lines += author_lines
      new_header_lines << "#"
      new_header_lines += copyright_lines
      new_header_lines << "#"
      new_header_lines << ("# "+cookbook.short_license_text.commentize) << '#'
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
      {
        :hostname     => 'hostname',
        :cluster_name => :cluster_name,
        :platform     => 'ubuntu',   :platform_version => '10.4',
        :cloud        => { :private_ips => ['10.20.30.40']    },
        :cpu          => { :total => 2 }, :memory => { :total => 2 },
        :kernel       => { :os => '', :release => '', :machine => '' ,},
        :ec2          => { :instance_type => 'm1.large',      },
        :hbase        => { :home_dir => '/usr/lib/hbase',     },
        :zookeeper    => { :home_dir => '/usr/lib/zookeeper', },
        :flume        => { :exported_jars => [] },
        :redis        => { :slave => 'no' },
        :ipaddress    => '10.20.30.40',
        :languages    => { :ruby => { :version => "1.9" } },
        :cassandra    => { :mx4j_version => 'x.x' },
        :ganglia      => { :home_dir => '/var/lib/ganglia' },
      }.merge(@all_attributes)
    end
    def method_missing(meth, *args)
      if args.empty? && node.has_key?(meth)
        node[meth]
      else
        super(meth, *args)
      end
    end

    def value_for_platform(hsh)
      hsh["default"] || hsh[hsh.keys.first]
    end

    def read
      self.execute!
      @header_lines = []
      @body_lines   = []
      comment_lines = []
      # look for comment lines that precede an attribute default statement.
      # adopt them as the attribute's description
      raw_lines.each do |line|
        if    line =~ /^#(.*)/
          comment = $1.strip
          comment_lines << comment if comment.present?
        elsif line =~ /^(default\[  [ \[\]\w\: ]+ \])/x
          attr = eval($1)
          attr.description = comment_lines.join("\n") if attr.is_a?(DummyAttribute)
          comment_lines = []
        else
          comment_lines = []
        end
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
    has_keys      :long_description
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

    # pull out the non-generated part of the README
    def long_description(val=nil)
      return @long_description.to_s if val.nil?
      lines = val.split(/\n/)
      until (not lines.last.blank?) || lines.empty? ; lines.pop ; end
      if lines.last =~ /^> readme generated by \[cluster_chef\]/
        # it's one of ours; strip out the generated material
        until (lines.first =~ /^## (Overview|Recipes)/) || lines.empty?
          lines.shift
        end
        desc = []
        lines.shift if lines.first =~ /^## (Overview)/
        until (lines.first =~ /^## Recipes/) || lines.empty?
          desc << lines.shift
        end
      else
        desc = lines
      end
      @long_description = desc.join("\n").strip
    end


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
      attr_branch[leaf].seen << :metadata
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
      attrib_file.all_attributes.attrs.each do |af_attrib|
        my_attrib = attribute(af_attrib.name)
        my_attrib.seen << :attrib_file
        af_attrib.description = my_attrib.description if my_attrib.description.present? # let the metadata.rb value win
        # puts [af_attrib.name, "  a "+af_attrib.description.split("\n").join("\n  a "), "  m "+my_attrib.description.split("\n").join("\n  m ")] if af_attrib.description.present? && my_attrib.description.present?
        my_attrib.merge!(af_attrib.to_hash)
      end
    end

    def lint!
      # Settings.each do |attr, sval|
      #   my_val = self.send(attr) rescue nil
      #   warn([name, attr, sval, my_val ]) unless sval == my_val
      # end
      lint_dependencies
      lint_presence
      lint_attributes
      components[:recipes].each(&:lint)
    end

    def lint_attributes
      # components[:attributes].each do |attrib_file|
      #   attrib_file.read
      # end
      all_attributes.attrs.each do |attrib|
        if ((attrib.seen.include?(:metadata)) && (not attrib.seen.include?(:attrib_file)) &&
            (not attrib.type == "hash") &&
            attrib.description !~ /\[set by recipe\]/)
          warn "Cookbook #{name} declares attribute #{attrib.name} in metadata but it is not in an attributes file, and does not state '[set by recipe]' in its metadata.rb description"
        end
      end
    end

    def lint_dependencies
      include_cookbooks = []
      components[:recipes].each do |recipe|
        include_cookbooks += recipe.include_cookbooks
      end
      include_cookbooks = include_cookbooks.sort.uniq
      missing_dependencies = (include_cookbooks  - all_depends.keys - [name])
      missing_includes     = (all_depends.keys - include_cookbooks  - [name])
      warn "Coookbook #{name} doesn't declare dependency on #{missing_dependencies.join(", ")}, but has an include_recipe that refers to it" if missing_dependencies.present?
      warn "Coookbook #{name} declares dependency on #{missing_includes.join(", ")}, but never calls include_recipe with it"             if missing_includes.present?
    end

    def lint_presence
      components[:recipes].each do |recipe|
        warn "Recipe #{name}::#{recipe.name} #{recipe.filename} missing, though it is alluded to in #{name}/metadata.rb" unless File.exists?(recipe.filename)
      end
    end

    def dump
      load_components
      lint!
      File.open(file_in_cookbook('metadata.rb.bak'), 'w') do |f|
        f << render('metadata.rb')
      end
      File.open(file_in_cookbook('README.md.bak'), 'w') do |f|
        f << render('README.md')
      end
      components[:recipes].each do |recipe|
        recipe.generate_header!
        recipe.dump
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

  puts "-----------------------------------------------------------------------"
  puts "\n\n++++++++++++++++ COOKBOOK MUNGE NOM NOM NOM +++++++++++++++++++\n\n"
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
