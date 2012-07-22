module Ironfan
  def self.deprecated call, replacement=nil
    correction = ", use #{replacement} instead" if replacement
    ui.warn "The '#{call}' statement is deprecated#{correction} (in #{caller(2).first.inspect})"
  end

  def self.future call, replacement=nil
    correction = ", we are ignoring it"
    correction = ", use #{replacement} instead" if replacement
    ui.warn "The '#{call}' statement isn't available yet#{correction} (in #{caller(2).first.inspect})"
  end

  module Dsl
    class Cloud
      def defaults
        Ironfan.deprecated 'defaults'
      end
    end
    
    class Compute
      def cloud(provider=nil)
        if provider.nil?
          Ironfan.deprecated 'cloud(nil)','cloud(:ec2)'
          provider = :ec2
        end
        super(provider)
      end
    end

  end
end
