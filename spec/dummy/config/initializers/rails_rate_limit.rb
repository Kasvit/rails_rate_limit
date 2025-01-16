# frozen_string_literal: true

RailsRateLimit.configure do |config|
  config.default_store = :memory
  config.redis_connection = Redis.new
  config.memcached_connection = Dalli::Client.new
  config.logger = Rails.logger
  config.default_on_controller_exceeded = lambda {
    render json: {
      error: "Too many requests",
      retry_after: response.headers["Retry-After"]
    }, status: :too_many_requests
  }
  config.default_on_method_exceeded = lambda {
    nil
  }
end
