# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conjur-policy-parser-version'

Gem::Specification.new do |spec|
  spec.name          = "conjur-policy-parser"
  spec.version       = Conjur::PolicyParser::VERSION
  spec.authors       = ["Kevin Gilpin"]
  spec.email         = ["kgilpin@gmail.com"]

  spec.summary       = %q{Parse the Conjur policy YAML format.}
  spec.homepage      = "https://github.com/conjurinc/conjur-policy-parser"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "safe_yaml"
  spec.add_dependency "activesupport", ">= 4.2"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-expectations"
  spec.add_development_dependency "ci_reporter_rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-cobertura"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "deepsort"
end
