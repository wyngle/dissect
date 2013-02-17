# bundler

require 'rubygems'
require 'bundler/setup'

$:.unshift 'lib'
require 'dissect'

# redirecting / to /_dissect

class ToDissect
  def initialize(app)
    @app = app
  end
  def call(env)
    if env['PATH_INFO'] == '/'
      [ 303, { 'Location' => '/_dissect', 'Content-Type' => 'text/plain' }, [] ]
    else
      @app.call(env)
    end
  end
end

use ToDissect

use Rack::CommonLogger
use Rack::Lint
use Rack::ShowExceptions

run Dissect::App

