module ClusterChef
  #
  # A private key -- chef client key, ssh key, etc.
  #
  # The key is a pro
  class PrivateKey < ClusterChef::DslObject
    attr_reader   :name
    attr_reader   :proxy
    attr_reader   :on_update

    #
    # PrivateKey.new('bob')
    #
    # @yield      a block, executed in caller's context, when the body is updated
    # @yieldparam the updated body
    def initialize(name, proxy=nil, &on_update)
      super()
      @name      = name
      @proxy     = proxy
      @on_update = on_update
    end

    def filename
      File.join(Chef::Config.keypair_path, "#{name}.pem")
    end
    
    def save
      return unless @body
      ui.info( "    key #{name} - writing to #{filename}" )
      File.open(filename, "w", 0600){|f| f.print( @body ) }
    end
    
    def load
      return unless File.exists?(filename)
      body = File.read(filename).chomp
    end

    def body=(content)
      @body = content
      on_update.call(content) if on_update
      content
    end

    def self.create!(name, *args, &block)
      obj = self.new(name, *args, &block)
      obj.create_proxy!
      obj
    end

    def to_s
      [super[0..-1], name, proxy].join(" ") + '>'
    end
  end

  class ChefClientKey < PrivateKey
    def body
      return @body if @body
      if proxy && proxy.private_key
        @body = proxy.private_key
      else
        load
      end
      @body
    end
  end

  class Ec2Keypair < PrivateKey

    def body
      return @body if @body
      if proxy && proxy.private_key
        @body = proxy.private_key
      else
        load
      end
      @body
    end

    def save
      (Chef::Log.debug("    key #{name} - dry run, not writing out key"); return) if ClusterChef.chef_config[:dry_run]
      # (Chef::Log.debug("  exists -- not writing out key");  return) if File.exists?(filename)
      super
    end

    def create_proxy!
      ui.info(ui.color("    key #{name} - creating"))
      @proxy = ClusterChef.fog_connection.key_pairs.create(:name => name)
      ClusterChef.fog_keypairs[name] = proxy
      self.body = proxy.private_key
      save
    end

  end
end
