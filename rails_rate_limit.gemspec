# frozen_string_literal: true

require_relative "lib/rails_rate_limit/version"

Gem::Specification.new do |spec|
  spec.name = "rails_rate_limit"
  spec.version = RailsRateLimit::VERSION
  spec.authors = ["Kasvit"]
  spec.email = ["kasvit93@gmail.com"]

  spec.summary     = "Flexible rate limiting for Rails applications"
  spec.description = "Flexible rate limiting with support for Redis, Memcached, and Memory storage"
  spec.homepage    = "https://github.com/kasvit/rails_rate_limit"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 2.7.6"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kasvit/rails_rate_limit"
  spec.metadata["changelog_uri"] = "https://github.com/kasvit/rails_rate_limit/blob/master/CHANGELOG.md"

  # Runtime dependencies
  spec.add_dependency "dalli"
  spec.add_dependency "rails", ">= 6.1.7.3"
  spec.add_dependency "redis-rails"

  # Development dependencies
  spec.add_development_dependency "fakeredis"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "timecop"

  spec.files = Dir["{app,config,lib}/**/*", "LICENSE.txt", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
