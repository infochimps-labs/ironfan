module Vagrant
  class IronfanEnvironment < Vagrant::Environment

    def initialize(opts={})
      super(opts)
      munge_logger(opts)
    end


  protected
    def munge_logger(opts)
      logger = Log4r::Logger.new("vagrant")
      logger.outputters = Log4r::Outputter.stderr
      logger.level = opts[:log_level] || 3
      logger.info( "ironfan vagrant (#{self}) - cwd: #{cwd}")
    end
  end
end
