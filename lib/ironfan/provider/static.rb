module Ironfan
  class Provider
    class Static < Ironfan::IaasProvider
      self.handle = :static

      def self.resources
        [ Machine ]
      end

      def self.ensure_tags(tags,fog)
        #  Ironfan.safely do
        #    config = {:key => k, :value => v.to_s, :resource_id => fog.id }
        #    connection.tags.create(config)
        #  end
        #end
      end

      def self.applicable(computer)
        computer.server and computer.server.clouds.include?(:static)
      end
    end
  end
end
