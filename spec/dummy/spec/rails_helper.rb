# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)

abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "rails_rate_limit" # Ensure your gem is required

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

RSpec.configure do |config|
  config.before(:each) do
    clean_database
  end
  config.after { Timecop.return }
end

def clean_database
  # Clean Redis
  Redis.new.flushdb

  # Clean Memcached
  RailsRateLimit.configuration.memcached_connection&.flush

  # Clean Memory store
  RailsRateLimit::Stores::Memory.instance.clear

  Rails.cache.clear
end
