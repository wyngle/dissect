require 'logger'

module Dissect
  def self.root
    # defined?(Rails) ? Rails.root : File.expand_path './'
    File.expand_path './'
  end

  def self.env
    @env ||= defined?(Rails) ? Rails.env : ENV['RACK_ENV'] || 'development'
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
