require 'fileutils'

module Ironfan
  #
  # A private key -- chef client key, ssh key, etc.
  #
  # The key is a pro
  class PrivateKey < Ironfan::DslObject
    attr_reader   :name
    attr_reader   :proxy
    attr_reader   :on_update

    #
    # PrivateKey.new('bob')
    #
    # @yield      a block, executed in caller's context, when the body is updated
    # @yieldparam the updated body
    def initialize(name, proxy=nil, &on_update)
      @name      = name
      @proxy     = proxy
      @on_update = on_update
    end

    def filename
      File.join(key_dir, "#{name}.pem")
    end

    def save
      return unless @body
      if Ironfan.chef_config[:dry_run]
        Chef::Log.debug("    key #{name} - dry run, not writing out key")
        return
      end
      ui.info( "    key #{name} - writing to #{filename}" )
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, "w", 0600){|f| f.print( @body ) }
    end

    def load
      return unless File.exists?(filename)
      self.body = File.read(filename).chomp
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
      [super[0..-2], @name, @proxy, @body.to_s[32..64], '...', @body.to_s[-60..-30]].join(" ").gsub(/[\r\n\t]+/,'') + '>'
    end
  end

  class ChefClientKey < PrivateKey
    def body
      return @body if @body
      if proxy && proxy.private_key && (not proxy.private_key.empty?)
        @body = proxy.private_key
      else
        load
      end
      @body
    end

    def key_dir
      Chef::Config.client_key_dir || '/tmp/client_keys'
    end
  end

  class DataBagKey < PrivateKey
    def body
      return @body if @body
      @body
    end

    def random_token
      require "digest/sha2"
      digest = Digest::SHA512.hexdigest(  Time.now.to_s + (1..10).collect{ rand.to_s }.join  )
      5.times{ digest = Digest::SHA512.hexdigest(digest) }
      digest
    end

    def key_dir
      return Chef::Config.data_bag_key_dir if Chef::Config.data_bag_key_dir
      dir = "#{ENV['HOME']}/.chef/data_bag_keys"
      warn "Please set 'data_bag_key_dir' in your knife.rb. Will use #{dir} as a default"
      dir
    end
  end

  class Ec2Keypair < PrivateKey
    def body
      return @body if @body
      if proxy && proxy.private_key && (not proxy.private_key.empty?)
        @body = proxy.private_key
      else
        load
      end
      @body
    end

    def create_proxy!
      safely do
        step("    key #{name} - creating", :green)
        @proxy = Ironfan.fog_connection.key_pairs.create(:name => name.to_s)
      end
      Ironfan.fog_keypairs[name] = proxy
      self.body = proxy.private_key
      save
    end

    def key_dir
      if Chef::Config.ec2_key_dir
        return Chef::Config.ec2_key_dir
      else
        dir = "#{ENV['HOME']}/.chef/ec2_keys"
        warn "Please set 'ec2_key_dir' in your knife.rb. Will use #{dir} as a default"
        dir
      end
    end
  end

end
