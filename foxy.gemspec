# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "foxy/version"

Gem::Specification.new do |spec|
  spec.name          = "foxy"
  spec.version       = Foxy::VERSION
  spec.authors       = ["Manuel Albarrán"]
  spec.email         = ["weap88@gmail.com"]

  spec.summary       = "Foxy tools for foxy things."
  spec.description   = "A set of foxy tools for make easy retrieve information for another servers."
  spec.homepage      = "https://github.com/weapp/foxyrb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|yml)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 0.15.4"
  spec.add_dependency "faraday-conductivity", "~> 0.3.1"
  spec.add_dependency "faraday_middleware", "~> 0.13.1"
  spec.add_dependency "htmlentities", "~> 4.3.4"
  spec.add_dependency "ibsciss-middleware", "~> 0.4.2"
  spec.add_dependency "multi_json", "~> 1.0"
  spec.add_dependency "patron", "~> 0.13.1"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "colorize"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rack-test", "~> 1.1.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "redis"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop"
end
