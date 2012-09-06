module Ironfan
  def self.deprecated call, replacement=nil
    correction = ", " if replacement
    ui.error "The '#{call}' statement is deprecated#{correction} (in #{caller(2).first.inspect}). It looks like you are using an outdated DSL definition: please see https://github.com/infochimps-labs/ironfan/wiki/Upgrading-to-v4 for all the necessary upgrade steps."
    exit(1)
  end

  class Dsl
    class Cloud
      def defaults
        Ironfan.deprecated 'defaults'
      end
    end
    
    class Compute
      def cloud(provider=nil)
        if provider.nil?
          Ironfan.deprecated 'cloud(nil)','use cloud(:ec2) instead'
          provider = :ec2
        end
        super(provider)
      end
    end

    class Volume
      def defaults
        Ironfan.deprecated 'defaults'
      end
    end

  end
end
