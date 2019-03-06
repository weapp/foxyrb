# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'foxy/version'

Gem::Specification.new do |spec|
  spec.name          = "foxy"
  spec.version       = Foxy::VERSION
  spec.authors       = ["Manuel Albarrán"]
  spec.email         = ["weap88@gmail.com"]

  spec.summary       = %q{Foxy tools for foxy things.}
  spec.description   = %q{A set of foxy tools for make easy retrieve information for another servers.}
  spec.homepage      = "https://github.com/weapp/foxyrb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 0.9.2"
  spec.add_dependency "faraday_middleware", "~> 0.10.0"
  spec.add_dependency "patron", "~> 0.6.1"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "colorize"
  spec.add_development_dependency "rspec", "~> 3.0"
end
