# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'dissect/version'

Gem::Specification.new do |gem|

  gem.name          = "dissect"
  gem.version       = Dissect::VERSION
  gem.platform      = Gem::Platform::RUBY
  gem.authors       = ['Kostas Karampinas','Gert van der Spoel']
  gem.email         = ['dissect@wyngle.com']
  gem.description   = %q{dissecting text files}
  gem.summary       = %q{designed for parsing e-shop confirmation emails, but should be flexible enough to dissect any (un)structured text it is fed}
  gem.homepage      = "http://github.com/wyngle/dissect"

  gem.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    "{lib}/**/*.rake", "{lib}/**/*.yml", 'lib/dissect/web/**/*',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})

  gem.add_runtime_dependency 'sinatra'
  gem.add_runtime_dependency 'sinatra-respond_to'
  gem.add_runtime_dependency 'mail'
  gem.add_runtime_dependency 'nokogiri'
  gem.add_runtime_dependency 'json'
  gem.add_runtime_dependency 'thor'

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rack"
  gem.add_development_dependency "rack-test"

  gem.require_paths = ["lib"]
end
