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

    def root
      File.expand_path '../../..', __FILE__
    end

    def empty_hash(values)
      ""
    end

    def to_plaintext(data, input_type)

      # TODO
      # better condition to determine if fixed width

      if input_type == "email"
        transfer_encoding = data.parts.first.content_transfer_encoding if data.multipart?
        Dissect.logger.info "Email body from #{data.from} is encoded with base 64 and could not be parsed"
        raise "Email is encoded with base64 and could not be parsed" if transfer_encoding == "base64"
        if data.multipart?
          mailhtml = data.body.decoded.gsub(/"/, '')
          str = Nokogiri::HTML(mailhtml).text
          str = str.gsub(/\n+|\r+|\t+/, '').squeeze("\n").strip.gsub(/\s{2,}/, ' ')
        else
          str = data.body.decoded.gsub(/"/, '')
        end
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

    # creates the regexp from the fixed width array given in the config file
    def array_to_regexp(arr)
      arr = arr.map { |x| "(.{" + x + "}?) " }
      arr.push('/').unshift('/')
      structure_reg = to_regexp(arr.join(""))
    end

    # maybe better -> identifier as dir and inside a yml file
    # def create_config_dir(identifier)
    #   Dir.mkdir(File.join(root, "config/dissect")) unless File.exists?(File.join(root, "config/dissect"))
    # end

    def set_config_paths
      @config_file_path = "config/dissect/"
    end

    def valid_input_types
      @valid_input  = ["email", "xml", "text"]
    end

    def valid_output_types
      @valid_output = ["json", "xml"]
    end

    def fixed_width_parser(op, struct, str)
      out = []
      p str
      str = str.scan(/(?<=#{op["parsing_start"]}).*?(?=#{op["parsing_end"]})/im)[0]
      str.split("\n").each do |line|
        line=line.ljust(op["max_line"])
        m = array_to_regexp(struct.values.map(&:to_s)).match(line).captures
        if m[0] !~ /\A\s*\z/ and m[0] !~ /\A[-*]\z/
          out << m
        else
          m.each_with_index do |x,i|
            next unless x !~ /\A\s*\z/
            out.last[i].rstrip
            out.last[i] += x.lstrip
          end
        end
      end

      orderline = []
      out.each do |o|
       o.each_with_index do |i,idx|
         order = i.strip.squeeze(' ')
         orderline << order
         @orderline = orderline
         # print ', ' unless idx == o.size - 1
       end
      end

      keys_arr = struct.keys
      output = Hash[keys_arr.collect { |v| [v, empty_hash(v)] }]
      order = @orderline.each_slice(struct.values.size).to_a

      final = []
      order.each do |orderl|
        final << (Hash[*output.keys.zip(orderl).flatten])
      end
      @output_stru = @options["multiple?"] ? Hash[@options["name"],final] : final[0]
    end

    def unstructured_parser(reg, str)

      # create the hash output
      keys_arr = reg.keys
      output = Hash[keys_arr.collect { |v| [v, empty_hash(v)] }]

      # take the regexes from yaml
      # accept all types of regexes -> non-capturing groups - named capturing groups - no groups
      #
      keys_arr.each do |name|
        regexp = to_regexp reg["#{name}"]
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
      @output_unstru = output
    end

    def result(hash, output_type)
      if output_type == "xml"
        @analyzed = to_xml(hash)
      else
        @analyzed = hash.to_json
        # @analyzed = JSON.pretty_generate(hash)
        # jj hash
      end
    end

    def regex_loader(identifier)
      begin
        yml = YAML.load_file(File.join(root, set_config_paths, "#{identifier}.yml"))
        Dissect.logger.info "Using #{identifier}.yml config file."
      rescue => err
        puts "Exception: #{err}"
        Dissect.logger.fatal "Exception: #{err.backtrace}"
      end
      @yml_parsed = yml
    end


    def process(data, identifier = ['default'], input_type = "email", output_type = "json")
      # puts 'data: ' + data
      puts 'identifier: '  + identifier.join("/")
      puts 'input_type: '  + input_type
      puts 'output_type: ' + output_type

      Dir.mkdir(File.join(root, set_config_paths)) unless File.exists?(File.join(root, set_config_paths))

      if data.nil? or data == ""
        Dissect.logger.fatal { "There are no incoming data." }
        raise "Error: Could not dissect for nil or empty data"
      else
        identifier  = identifier.last
        unless valid_input_types.include?(input_type) and valid_output_types.include?(output_type)
          raise "Wrong type of input or output parameter\nValid Types\nInput:#{valid_input_types}
          \nOutput:#{valid_output_types} "
        end


        # which config file to use?
        if identifier.nil?
          Dissect.logger.fatal { "Argument 'identifier' not given. \n
            Give the name of the config YML file under #{set_config_paths} directory" }
          raise "Error: Argument identifier is nil "
        else
          regex_loader identifier
        end

        # config file options - regexes for structured data
        @options = @yml_parsed["fixed_structure"]["options"]

        @rest_regexes  = @yml_parsed["fixed_structure"]["rest_regexes"]
        @structure = @yml_parsed["fixed_structure"]["options"]["structure"]

        # config file regexes for untructured data
        @regexes = @yml_parsed["non_fixed_structure"]["regexes"]

        str = to_plaintext(data, input_type)

        if @options["multiple?"] or @options["multiline?"]
          fixed_width_parser @options, @structure, str
          if @options["has_also_unstructured_data?"]
            unstructured_parser @rest_regexes, str
            @output = @output_stru.merge(@output_unstru)
          else
            @output = @output_stru
          end
        else
          unstructured_parser @regexes, str
          @output = @output_unstru
        end

        result @output, output_type

        return @analyzed
      end
    end

  end

end
