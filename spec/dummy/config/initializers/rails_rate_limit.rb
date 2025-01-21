# frozen_string_literal: true

RailsRateLimit.configure do |config|
  # Use memory store by default (good for development)
  config.default_store = :memory

  # Configure Redis connection (for production)
  config.redis_connection = Redis.new

  # Configure Memcached connection (for production)
  config.memcached_connection = Dalli::Client.new

  # Configure logging
  config.logger = Rails.logger

  # Configure default handler for controllers
  # config.handle_controller_exceeded = -> {
  #   render json: {
  #     error: "Too many requests",
  #     retry_after: response.headers["Retry-After"]
  #   }, status: :too_many_requests
  # }

  # Configure default handler for methods
  # By default, it raises RailsRateLimit::RateLimitExceeded
  # config.handle_klass_exceeded = -> {
  #   #raise RailsRateLimit::RateLimitExceeded, "Rate limit exceeded"
  #   nil
  # }
end
