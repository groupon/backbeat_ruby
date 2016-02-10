lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "backbeat/version"

Gem::Specification.new do |spec|
  spec.name          = "backbeat"
  spec.version       = Backbeat::VERSION
  spec.authors       = ["FED"]
  spec.email         = ["fed@groupon.com"]
  spec.homepage      = "https://github.groupondevcom/finance-engineering/backbeat_ruby_client"
  spec.description   = "Ruby client for the Backbeat workflow service"
  spec.summary       = "Ruby client for the Backbeat workflow service."
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'multi_json', '~> 1.11'
  spec.add_runtime_dependency 'activesupport', '> 3.2'

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 1.20'
  spec.add_development_dependency 'surrogate', '~> 0.8'
end
