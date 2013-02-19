# encoding: utf-8
require "dissect/version"
require "dissect/init"
require 'mail'
require 'nokogiri'
require 'yaml'
require 'json'


class String
  def scan2(regexp)
    names = regexp.names
    scan(regexp).collect do |match|
      Hash[names.zip(match)]
    end
  end
end

module Dissect

  autoload :App, 'dissect/web/app'

  class << self

    def env
      @env ||= defined?(Rails) ? Rails.env : ENV['RACK_ENV'] || 'development'
    end

    def empty_hash(values)
      ""
    end

    def to_plaintext(mail)
      mailhtml = mail.body.decoded.gsub(/"/, '')
      @str  = Nokogiri::HTML(mailhtml).text
      return @str
    end

    def to_regexp(yaml)
      split = yaml.split("/")
      options = (split[2].include?("x") ? ::Regexp::EXTENDED : 0) |
        (split[2].include?("i") ? ::Regexp::IGNORECASE : 0) |
        (split[2].include?("m") ? ::Regexp::MULTILINE : 0) unless split[2].nil?
        ::Regexp.new(split[1], options)
    end

    def root
      File.expand_path '../..', __FILE__
    end

    # maybe better -> identifier as dir and inside a yml file
    # def create_config_dir(identifier)
    #   Dir.mkdir(File.join(root, "config/dissect")) unless File.exists?(File.join(root, "config/dissect"))
    # end

    def process(data, identifier, input_type = "email", output_type = "json")
      puts 'data: ' + data
      puts 'identifier: '  + identifier.join(",")
      puts 'input_type: '  + input_type
      puts 'output_type: ' + output_type

      Dir.mkdir(File.join(root, "config/dissect")) unless File.exists?(File.join(root, "config/dissect"))

      unless data.nil? or data == ""
        if input_type == "email"
          str    = to_plaintext(data)
        elsif input_type == "xml"
          p "do something for xml parsing"
        elsif input_type == "text"
          p "do something for plain text input"
        end


        # which config file to use?
        if File.exists?(File.expand_path("../config/#{identifier}.yml"))
          regexes = YAML.load_file(File.join(root, "config/dissect/#{identifier}.yml"))
          Dissect.logger.info "Using #{identifier}.yml config file."
        else
          identifier="default"
          regexes = YAML.load_file(File.join(root, "config/dissect/default.yml"))
          Dissect.logger.info "Using the default.yml config file."
        end

        # create the hash output
        keys_arr = regexes["#{regexes.keys[0]}"].keys
        output = Hash[keys_arr.collect { |v| [v, empty_hash(v)] }]

        # take the regexes from yaml
        keys_arr.each do |name|
          regexp = to_regexp regexes["#{regexes.keys[0]}"]["#{name}"]
          match  = (str.scan2 regexp)[0].nil? ? "" : (str.scan2 regexp)[0]["#{name}"]
          output[name] = match
        end

        # ----------------------------------------

        analyzed = j @output

        return @output    #hash
        return analyzed   #json
      end

    end

  end

end
