require 'sinatra/respond_to'
require 'erb'

module Dissect
  class App < Sinatra::Application

    register Sinatra::RespondTo

    configure do
      if defined?(Rails)  # we want to support Rails
        set :environment, Rails.env
        disable :raise_errors unless Rails.env == 'development'
      end
    end

    set :views, File.join(File.dirname(__FILE__), 'views')

    use(
      Rack::Static,
      :urls => %w[ /_dissect/stylesheets /_dissect/javascripts ],
      :root => File.join(File.dirname(__FILE__), 'public'))

    use(
      Rack::MethodOverride)

    Dir[File.join(File.dirname(__FILE__), 'helpers/*.rb')].each{|r| load r}

    helpers do
      include Dissect::Helpers::RenderHelpers
    end

    unless defined?(Rails)
      # handle 404s ourselves when not in Rails
      not_found do
        http_error(404)
      end
    end


    get '/_dissect' do
      @root = Dissect.root
      @title = "Dissect"
      respond_to do |format|
        format.html do
          erb :list
        end
      end
    end

    post '/_dissect' do
      dissector = params[:dissector]
      regexes = Dissect::regex_loader(dissector)
      regkeys = regexes["#{regexes.keys[0]}"].keys
      @regkeys = regkeys
      regkeys.each do |name|
        instance_variable_set("@" + name, regexes["#{regexes.keys[0]}"]["#{name}"])
      end
      @id = "#"
      @name = "Name"
      @reg = "Regular Expresion"

      respond_to do |format|
        format.html do
          erb :list
        end
      end
    end

    # save updated yml
    post '/save' do
      @kati = parmas["saveit"]
      #   @test = params["newyml"]
      #   File.open('test.yml', 'w') do |f|
      #   f.write params["newyml"]
      # end
      respond_to do |format|
        format.html do
          erb :save
        end
      end
    end

    # load email to tester
    get '/_dissect/email' do
      @mail = params[:mail]
      @email = Mail.read(@mail)
      # @str_mail = Dissect.to_plaintext(@email, "email")
    end

    # regex tester
    post '/_dissect/regex' do
      if !request.params["regex"].empty?
        # pattern = Regexp.new(params[:regex])
        begin
          pattern = Regexp.new(params["regex"])
          matches = pattern.match(params["subject"])
          # matches = params["subject"].scan2 pattern
          if matches.nil?
           resp=  "Nothing Matched"
          else
           resp= matches.to_a
          end
        rescue RegexpError => error
          resp="Regexp error"
        end
      end
      if resp == ''
        respond_to do |format|
          format.html do
            erb :'/'
          end
        end
      else
        content_type :json
        { :resp => resp }.to_json
      end
    end

    #test dissect
    get '/_dissect/testme' do
      @root = Dissect::root
      # @identifier =  Dir.glob(File.join(@root, "config/dissect/*"))
      @valid_input  = Dissect::valid_input_types
      @valid_output = Dissect::valid_output_types
      respond_to do |format|
        format.html do
          erb :'testme'
        end
      end
    end

    post '/_dissect/testme' do
      data = params[:data]
      identifier = params[:identifier].split(",")
      # data = identifier = "email" ? Mail.new(params[:data]) : params[:data]
      input_type = params[:input_type]
      output_type = params[:output_type]

      @valid_input  = Dissect::valid_input_types
      @valid_output = Dissect::valid_output_types

      start = Time.now
      results = Dissect.process(data, identifier, input_type, output_type)
      @bench = "Time elapsed: #{Time.now - start} seconds"

      class Hash
        def to_html_table
          rows=self.collect do |k,v|
            "<tr><td>#{k}</td><td>#{v}</td></tr>"
          end
          "<table border=1 cellspacing=0 cellpadding=3>#{rows}</table>"
        end
      end
      @table = results

      respond_to do |format|
        format.html do
          erb :'testme'
        end
      end
    end

  end
end
