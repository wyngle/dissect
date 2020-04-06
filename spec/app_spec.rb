require File.dirname(__FILE__) + '/spec_helper'

describe 'Dissect dashboard' do

  include Rack::Test::Methods

  def app
    @app ||= Dissect::App
  end

  it "should load the home page" do
    get '/_dissect'
    last_response.should be_ok
  end

  it "should load the /testme page" do
    get '/_dissect/testme'
    last_response.should be_ok
  end

  it "should load the /new page" do
    get '/_dissect/new'
    last_response.should be_ok
  end

  # before :each do
  #   post '/_dissect/new ', {:identifier => "test", :names => {"testreg", :new => "i", :regulars => "a\regex\d"}
  # end

  # it "should create a standard hash" do
  #   last_response.body.should be_an_instance_of(Hash)
  #   # should_receive(:create).with({:title => 'Mr'})
  #   # post 'create' , :client => {"title" => "Mr" }
  # end

end
