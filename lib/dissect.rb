# encoding: utf-8
require "dissect/version"
require "dissect/init"
require 'mail'
require 'nokogiri'
require 'yaml'
# YAML::ENGINE.yamler = "syck"
require 'json'
require 'fileutils'

require "dissect/empty_hash.rb"
require "dissect/scan2.rb"
require "dissect/errors.rb"



module Dissect

  autoload :App, 'dissect/web/app'

  class << self

    def to_plaintext(data, input_type)

      # TODO
      # better condition to determine if fixed width
      # we dont want to squeeze if structured data
      #

      if input_type == "email"

        if data.multipart?
          transfer_encoding = data.parts.first.content_transfer_encoding
          if transfer_encoding == "base64"
            er = Error::Encoded.new
            Dissect.logger.info er
            raise er
          end
          # if general_options == "unstructured"
            mailhtml = data.body.decoded.gsub(/"/, '')
            str = Nokogiri::HTML(mailhtml).text
            str = str.gsub(/\n+|\r+|\t+/, '').squeeze("\n").strip.gsub(/\s{2,}/, ' ')
          # else
            # str = data.body.decoded.gsub(/"/, '')
          # end
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
    #
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

    def set_generators_paths
      @generator_file_path = "dissect/lib/generators/config/dissect.yml"
    end

    def set_config_dir
      if File.exists?(File.join(root, set_config_paths))
        return
      else
        FileUtils.mkpath File.join(root, set_config_paths)
        FileUtils.cp_r File.expand_path(set_generators_paths), File.join(root, set_config_paths)
      end
    end

    def valid_input_types
      @valid_input  = ["email", "xml", "text"]
    end

    def valid_output_types
      @valid_output = ["json", "xml"]
    end

    def structured_parser(op, struct, str)
      out = []
      if str=~/(?<=#{op["parsing_start"]}).*?(?=#{op["parsing_end"]})/im
        @str = str.scan(/(?<=#{op["parsing_start"]}).*?(?=#{op["parsing_end"]})/im)[0]
        @str.split("\n").each do |line|
          line=line.ljust(op["max_line"]).gsub(/\+/, ' ') #gsub for ascii art tables
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
        output = Hash[keys_arr.collect { |v| [v, Dissect::EmptyHash.new(v)] }]
        order = @orderline.each_slice(struct.values.size).to_a

        final = []
        order.each do |orderl|
          final << (Hash[*output.keys.zip(orderl).flatten])
        end
        if final.map(&:values).flatten.empty?
          @output_stru = {:error=>"No matches"}
        else
          @output_stru = op["multiple?"] ? Hash[op["name"],final] : final[0]
        end
      else
        er = Error::StructureDataEr.new
        Dissect.logger.fatal er
        raise er
      end
    end

    def unstructured_parser(reg, str)

      # create the hash output
      keys_arr = reg.keys
      output = Hash[keys_arr.collect { |v| [v, Dissect::EmptyHash.new(v)] }]

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
      @output_unstru = output.values.reject(&:empty?).empty? ? {:error=>"No matches"} : output
    end

    def result(hash, output_type)
      if output_type == "xml"
        @analyzed = to_xml(hash)
      else
        @analyzed = hash.to_json
        # @analyzed = JSON.pretty_generate(hash)
        # jj hash
        raise NoMatches::new if @analyzed.length <= 2
      end
    end

    def regex_loader(identifier)
      begin
        ident_file = File.join(root, set_config_paths, "#{identifier}.yml")
        Dissect.logger.info("Dissecting with: " + ident_file)
        yml = YAML.load_file(ident_file)
      rescue => err
        Dissect.logger.fatal "Exception: #{err.backtrace}"
        Dissect.logger.fatal "Exception: #{err.message}"
        return { "Error loading file"=> "#{err.message}"}.to_json
      end
      @yml_parsed = yml
    end

    def valid_identifier
      files =  Dir.glob(File.join(root, set_config_paths) + "*")
      valid_identifiers = []
      files.each do |fi|
        valid_identifiers << File.basename(fi, '.*').downcase
      end
      return valid_identifiers
    end

    def process(data, identifier = ['default'], input_type = "email", output_type = "json")

      set_config_dir

      if data.blank?
        er = Error::NoData.new
        Dissect.logger.fatal er
        raise er
      else

        # Case-insensitive parameter check
        unless valid_input_types.any?{ |s| s.casecmp(input_type)==0 } and valid_output_types.any?{ |s| s.casecmp(output_type)==0 }
          er = Error::ConfigFileError.new "not valid input or output argument"
          Dissect.logger.fatal "#{er}\nValid Types\nInput:#{valid_input_types}\nOutput:#{valid_output_types}"
          raise er
        end

        identifier = File.basename(identifier.last.split("/").last, '.yml').downcase unless identifier.nil?

        # which config file to use?
        unless valid_identifier.include?(identifier)
          er = Error::ConfigFileError.new "can't parse for nil identifier"
          Dissect.logger.fatal "#{er}\n valid identifiers at #{set_config_paths}"
          raise er
        else
          regex_loader identifier
        end

        # puts 'identifier: '  + identifier
        # puts 'input_type: '  + input_type
        # puts 'output_type: ' + output_type

        general_options = @yml_parsed["general_options"]["data_classification"]

        # config file options - regexes for structured data
        options = @yml_parsed["structured"]["options"]
        structured_regexes  = @yml_parsed["structured"]["regexes"]
        structure = @yml_parsed["structured"]["options"]["structure"]

        # config file regexes for untructured data
        if @yml_parsed["unstructured"]["regexes"].nil?
          # raise "No regexes found. Check your config file '#{identifier}.yml'"
          er = Error::ConfigFileError.new "No regexes found. Check your config file '#{identifier}.yml'"
          Dissect.logger.info er
          raise er
        else
          unstructured_regexes = @yml_parsed["unstructured"]["regexes"]
        end

        str = to_plaintext(data, input_type)

        if general_options == "structured"
          structured_parser options, structure, str
          if options["has_also_unstructured_data?"]
            unstructured_parser structured_regexes, str
            @output = @output_stru.merge(@output_unstru)
          else
            @output = @output_stru
          end
        else
          unstructured_parser unstructured_regexes, str
          @output = @output_unstru
        end

        result @output, output_type

        return @analyzed
      end
    end

  end

end
