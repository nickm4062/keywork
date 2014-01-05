# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'keywork/constants'

Gem::Specification.new do |spec|
  spec.name          = 'keywork'
  spec.version       = Keywork::VERSION
  spec.authors       = ['nickm4062']
  spec.email         = ['nick@nickmontgomery.com']
  spec.description   = %q{Replacement for Carbon compatible with graphite protocol}
  spec.summary       = %q{Replacement for Carbon}
  spec.homepage      = ''
  spec.license       = 'MIT'
  spec.has_rdoc    = false

  spec.files         = `git ls-files`.split($/)
  spec.executables   = Dir.glob('bin/**/*').map { |file| File.basename(file) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  
  spec.add_dependency 'oj', '2.0.9'
  spec.add_dependency 'eventmachine', '1.0.3'
  spec.add_dependency 'em-worker', '0.0.2'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'em-http-request'
end
