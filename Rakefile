require 'rubygems'
require 'rubygems/user_interaction' if Gem::RubyGemsVersion == '1.5.0'
require 'bundler'

require 'rake'
require 'rake/clean'
require 'rdoc/task'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks


#
# clean

CLEAN.include('pkg', 'rdoc')


#
# test / spec

RSpec::Core::RakeTask.new

task :test => :spec
task :default => :spec


