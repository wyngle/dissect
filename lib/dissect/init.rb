require 'logger'

module Dissect
  def self.root
    File.expand_path '../..', __FILE__
  end

  def self.logger
    @@logger ||= setup_logger
  end

  def self.setup_logger
    logger = Logger.new File.expand_path(File.join(root, 'dissect.log'))
    logger.formatter = proc { |severity, datetime, progname, msg|
      "[#{datetime}] #{severity}: #{msg}\n"
    }
    return logger
  end
end
