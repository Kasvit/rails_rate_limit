# frozen_string_literal: true

require "rails_rate_limit"
require "rails"
require "rails/generators"
require "fileutils"
require "fakeredis"
require "timecop"
require "dalli"
require "logger"

RailsRateLimit.configure do |config|
  config.default_store = :memory
  config.redis_connection = Redis.new
  config.memcached_connection = Dalli::Client.new("localhost:11211")
  config.logger = nil
end

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    # Clean Redis
    Redis.new.flushdb

    # Clean Memcached
    RailsRateLimit.configuration.memcached_connection&.flush

    # Clean Memory store
    RailsRateLimit::Stores::Memory.instance.clear
  end

  config.after { Timecop.return }

  config.pattern = "spec/lib/**/*_spec.rb"
end
