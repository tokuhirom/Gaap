# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gaap/version'

Gem::Specification.new do |gem|
  gem.name          = "gaap"
  gem.version       = Gaap::VERSION
  gem.authors       = ["tokuhirom"]
  gem.email         = ["tokuhirom@gmail.com"]
  gem.description   = %q{Simple web application framework}
  gem.summary       = %q{Simple web application framework}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('router_simple', '~>0.0.1')
  gem.add_dependency('rack', "~> 1.4.1")
  gem.add_dependency('erubis', '~> 2.7.0')
  gem.add_dependency('json', '~> 1.7.5')
  gem.add_dependency('rack-protection')
  gem.add_dependency('rack-test')
  gem.add_dependency('bundler')
  gem.add_dependency('rake', '~> 10.0.3')

  gem.add_development_dependency('httpclient')
end
