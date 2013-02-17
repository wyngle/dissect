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

    def tohash (re)
      @price_hash = (@str.scan2 re)[0]
    end

    def thesender(mail)
      @sender = mail.from
      @sender = @sender.to_s.gsub(/[\[\]]/, "").tr('"', '').split("@")[1]
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

    def result(order_no, quantity, vat, price, currency)
      @output = {"Order number" => "", "Quantity" => "", "Price" => "", "Vat" => "" }
      @output["Order number"] = order_no
      @output["Quantity"] = quantity
      @output["Vat"] = vat
      @output["Price"] = price
      @output["Currency"] = currency
      return @output
    end

    def process (arg)

      begin
        mail = Mail.read(arg)
      rescue => err
        puts "Exception: #{err}"
        Dissect.logger.fatal "Exception: #{err.backtrace}"
        err
      end

      sender = thesender(mail)
      str    = to_plaintext(mail)

      if File.exists?(File.expand_path("../config/#{sender}.yml"))
        regexes = YAML.load_file(File.expand_path("../config/#{sender}.yml"))
        Dissect.logger.info "Using #{sender}.yml config file."
        price_reg   = to_regexp regexes["#{sender}"]["price"]
        @price_hash = (@str.scan2 price_reg)[0]
      else
        sender="generic"
        regexes = YAML.load_file(File.expand_path("../generic.yml"))
        Dissect.logger.info "Using the generic.yml config file."

        price_cur_front_big = to_regexp regexes["#{sender}"]["price_cur_front_big"]
        price_cur_end_big   = to_regexp regexes["#{sender}"]["price_cur_end_big"]
        price_cur_end       = to_regexp regexes["#{sender}"]["price_cur_end"]
        price_cur_front     = to_regexp regexes["#{sender}"]["price_cur_front"]

        if str =~ price_cur_front_big
          tohash(price_cur_front_big)
        elsif str =~ price_cur_end_big
          tohash(price_cur_end_big)
        elsif str =~ price_cur_end
          tohash(price_cur_end)
        elsif str =~ price_cur_front
          tohash(price_cur_front)
        end
      end

      orderno_reg = to_regexp regexes["#{sender}"]["orderno"]
      qty_reg     = to_regexp regexes["#{sender}"]["qty"]
      vat_reg     = to_regexp regexes["#{sender}"]["vat"]

      # ----------------------------------------

      order_no = (str.scan2 orderno_reg)[0].nil? ? "no order number found" : (str.scan2 orderno_reg)[0]["ordernumber"]

      quantity = (str.scan2 qty_reg)[0].nil? ? "no item quantity found" : (str.scan2 qty_reg)[0]["quantity"]

      vat = (str.scan2 vat_reg)[0].nil? ? "no vat found" : (str.scan2 vat_reg)[0]["vat"]

      @price_hash["cent"] = @price_hash["cent"].nil? ? ".00" : @price_hash["cent"]
      price = @price_hash["dec"]+@price_hash["cent"]
      @price_hash["cu"] = @price_hash["cu"]=~/eu.*?/i ? "€" : @price_hash["cu"]
      currency = @price_hash["cu"]
  
      result order_no, quantity, vat, price, currency
      # puts @output
      analyzed = j @output

      return @output
      return analyzed
    end

  end

end
