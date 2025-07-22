require 'thor'
require 'dissect'
require 'dissect/generators/configuration'
module Dissect
  class CLI < Thor
    desc "configuration", "Generates a config file scaffold"
    def configuration(group, name)
      Dissect::Generators::Configuration.start([group, name])
    end
  end
end
