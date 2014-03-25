# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cinch/test/version'

Gem::Specification.new do |gem|
  gem.name          = 'cinch-test'
  gem.version       = Cinch::Test::VERSION
  gem.authors       = ['Jay Adkisson', 'Brian Haberer']
  gem.email         = ['jay@jayferd.us']
  gem.summary       = %q{Helpers for testing Cinch Plugins}
  gem.description   = %q{A collection of utility methods, mocks and methods for testing Cinch plugins}
  gem.homepage      = 'http://github.com/jayferd/cinch-test'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency  'coveralls'
  gem.add_development_dependency  'minitest'
  gem.add_development_dependency  'wrong'
  gem.add_development_dependency  'rake'
  gem.add_development_dependency  'rr'
  gem.add_development_dependency  'debugger'

  gem.add_dependency              'cinch',       '~> 2.0.0'
end
