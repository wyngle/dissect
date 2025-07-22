require 'logger'

module Dissect
  def self.root
    # File.expand_path '../../'
    # "/tmp"
    defined?(Rails) ? Rails.root.to_s : ENV['DISSECT_ROOT']
  end

  def self.log_path
    defined?(Rails) ? Rails.root.join('log').to_s : File.join(ENV['DISSECT_ROOT'], 'log')
  end

  def self.env
    @env ||= defined?(Rails) ? Rails.env : ENV['RACK_ENV'] || 'development'
  end

  def self.logger
    @@logger ||= setup_logger
  end

  def self.setup_logger
    unless File.exists?(log_path)
      FileUtils.mkpath log_path
    end
    logger = Logger.new(File.join(log_path, 'dissect.log'))
    logger.formatter = proc { |severity, datetime, progname, msg|
      "[#{datetime}] #{severity}: #{msg}\n"
    }
    return logger
  end
end
