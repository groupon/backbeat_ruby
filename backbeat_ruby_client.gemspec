Gem::Specification.new do |spec|
  spec.name          = "backbeat_ruby_client"
  spec.version       = "1.0.0"
  spec.authors       = ["FED"]
  spec.email         = ["fed@groupon.com"]
  spec.homepage      = "https://github.groupondevcom/finance-engineering/backbeat_ruby_client"
  spec.summary       = "Ruby client for the Backbeat workflow service."
  spec.description   = "Ruby client for the Backbeat workflow service."

  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'httparty', '~> 0.13.1'
  spec.add_runtime_dependency 'multi_json', '~> 1.7.5'
  spec.add_runtime_dependency 'activesupport', '>= 4.0.0', '< 5.0'

  spec.add_development_dependency 'rspec', '2.14.1'
  spec.add_development_dependency 'webmock', '1.17.4'
end
