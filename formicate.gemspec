# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'formicate/version'

Gem::Specification.new do |spec|
  spec.name          = "formicate"
  spec.version       = Formicate::VERSION
  spec.authors       = ["Benjamin Randles-Dunkley"]
  spec.email         = ["ben@chemica.co.uk"]
  spec.summary       = %q{A simple and flexible form object for Rails and Ruby applications using big helpings of conventions and syntactic sugar in true Rails style.}
  spec.description   = %q{A simple and flexible form object for Rails and Ruby applications using big helpings of conventions and syntactic sugar in true Rails style. Formicate uses ActiveModel for validations and seamless integration into the Rails workflow.}
  spec.homepage      = "https://github.com/chemica/formicate"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
end
