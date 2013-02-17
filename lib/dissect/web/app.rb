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
      @title = "Dissect" 
      respond_to do |format|
        format.html do
          erb :list
        end
      end
    end

    post '/_dissect' do
      @dissector = params[:dissector]
      @regex = YAML.load_file(File.expand_path(@dissector))
      partner_host = File.basename(@dissector, '.*')
      @partner_host = partner_host
      regkeys = @regex["#{partner_host}"].keys
      @regkeys = regkeys
      regkeys.each do |name|
        instance_variable_set("@" + name, @regex["#{partner_host}"]["#{name}"])
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


    get '/dropdown' do
      @select = params[:selected]
      respond_to do |format|
        format.html do
          erb :dropdown
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
      @str_mail = Dissect.to_plaintext(@email)
    end

    # regex tester
    post '/regex' do
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

    get '/testme' do
      respond_to do |format|
        format.html do
          erb :'testme'
        end
      end
    end

    post '/testme' do
      email = params[:email]
      start = Time.now
      results = Dissect.process(email)
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
