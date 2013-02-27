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

  it "should load the testme page" do
    get '/_dissect/testme'
    last_response.should be_ok
  end

end
