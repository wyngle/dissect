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

    def to_plaintext(data, input_type)
      if input_type == "email"
        mailhtml = data.body.decoded.gsub(/"/, '')
        # write a better regex to determine if base64
        raise "Email is encoded with base64 and could not be parsed" if mailhtml=~/encoding: base64/i
        str = Nokogiri::HTML(mailhtml).text
        str = str.gsub(/\n+|\r+|\t+/, "").squeeze("\n").strip.gsub(/\s{2,}/, ' ')
      elsif input_type == "xml"
        str = Nokogiri::XML(mailhtml).text
      else
        str = data
      end
      return str
    end

    def to_regexp(yaml)
      split = yaml.split("/")
      options = (split[2].include?("x") ? ::Regexp::EXTENDED : 0) |
        (split[2].include?("i") ? ::Regexp::IGNORECASE : 0) |
        (split[2].include?("m") ? ::Regexp::MULTILINE : 0) unless split[2].nil?
        ::Regexp.new(split[1], options)
    end

    def to_xml(hash)
      builder = Nokogiri::XML::Builder.new do
        contents {
          hash.each {|key,value|
            content(:id => key) {
              string {
                text value
              }
            }
          }
        }
      end
    return builder.to_xml()
    end

    def root
      File.expand_path '../../..', __FILE__
    end

    # maybe better -> identifier as dir and inside a yml file
    # def create_config_dir(identifier)
    #   Dir.mkdir(File.join(root, "config/dissect")) unless File.exists?(File.join(root, "config/dissect"))
    # end

    def result(hash, output_type)
      if output_type == "xml"
        analyzed = to_xml(hash)
      else
        analyzed = hash.to_json
        jj hash
      end
    end

    def parser(regexes, str)
      # create the hash output
      keys_arr = regexes["#{regexes.keys[0]}"].keys
      output = Hash[keys_arr.collect { |v| [v, empty_hash(v)] }]

      # take the regexes from yaml
      # accept all types of regexes -> non-capturing groups - named capturing groups - no groups
      #
      keys_arr.each do |name|
        regexp = to_regexp regexes["#{regexes.keys[0]}"]["#{name}"]
        if regexp.named_captures.values.size > 1
          match = (str.scan2 regexp)[0].nil? ? "" : (str.scan2 regexp)[0]
        elsif regexp.named_captures.values.size == 1
          match = (str.scan regexp)[0].nil? ? "" : (str.scan regexp)[0][0]
        else  #with non-named groups or no groups at all
          if (str.scan regexp)[0].kind_of?(Array)
            match = (str.scan regexp)[0].nil? ? "" : (str.scan regexp)[0].compact
            match = match[0][0] if match.size == 1
          else
            match = str.scan regexp
          end
        end
        output[name] = match
      end
      @output = output
    end

    def process(data, identifier = ['default'], input_type = "email", output_type = "json")
      # puts 'data: ' + data
       puts 'identifier: '  + identifier.join("/")
       puts 'input_type: '  + input_type
       puts 'output_type: ' + output_type

      Dir.mkdir(File.join(root, "config/dissect")) unless File.exists?(File.join(root, "config/dissect"))

      unless data.nil? or data == ""
        identifier  = identifier.last
        input_type_valid  = ["email", "xml", "text"]
        output_type_valid = ["json", "xml"]
        unless input_type_valid.include?(input_type) and output_type_valid.include?(output_type)
          raise "Wrong type of input or output parameter\nValid Types\nInput:#{input_type_valid}
          \nOutput:#{output_type_valid} "
        end

        str = to_plaintext(data, input_type)

        # which config file to use?
        if identifier.nil?
          Dissect.logger.fatal { "Argument 'identifier' not given. \n
            Give the name of the config YML file under config/dissect directory" }
          raise "Error: Argument identifier is nil "
        else
          begin
            regexes = YAML.load_file(File.join(root, "config/dissect/#{identifier}.yml"))
            Dissect.logger.info "Using #{identifier}.yml config file."
          rescue => err
            puts "Exception: #{err}"
            Dissect.logger.fatal "Exception: #{err.backtrace}"
          end
        end

        parser regexes, str

        result @output, output_type

        # return analyzed
      end
    end

  end

end
