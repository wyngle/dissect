require 'thor/group'
require 'dissect/generators/configuration'
module Dissect
  module Generators
    class Configuration < Thor::Group
      argument :group, :type => :string
      argument :name, :type => :string
      include Thor::Actions

      def self.source_root
        File.dirname(__FILE__) + "/config"
      end

      def create_group
        empty_directory(group)
      end

      def copy_dissect
        template("dissect.yml", "#{group}/#{name}.yml")
      end

    end
  end
end