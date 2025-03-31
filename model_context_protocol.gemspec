# model_context_protocol.gemspec
require_relative 'lib/model_context_protocol/version'

Gem::Specification.new do |spec|
  spec.name          = "model_context_protocol"
  spec.version       = ModelContextProtocol::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "Ruby implementation of the Model Context Protocol"
  spec.description   = "A Ruby SDK for building Model Context Protocol servers and clients"
  spec.homepage      = "https://github.com/yourusername/model_context_protocol"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir['lib/**/*', 'LICENSE.txt', 'README.md']
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "json-schema", "~> 3.0"
  spec.add_dependency "dry-schema", "~> 1.13"
  spec.add_dependency "dry-validation", "~> 1.10"
  spec.add_dependency "concurrent-ruby", "~> 1.2"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "pry", "~> 0.6"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
end
