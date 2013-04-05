require 'simplecov'
SimpleCov.start

# Path to your real ruby(sinatra) application
require File.join(File.dirname(__FILE__), '..', 'lib/dissect/web/app.rb')
require 'rubygems'
require 'sinatra'
require 'dissect'
require 'rack/test'
require 'rspec'

# set test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

