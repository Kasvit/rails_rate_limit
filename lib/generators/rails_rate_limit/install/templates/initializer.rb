# frozen_string_literal: true

RailsRateLimit.configure do |config|
  # Choose your storage backend (default: :memory)
  # Available options: :redis, :memcached, :memory
  # config.default_store = :memory

  # Configure Redis connection (required if using Redis store)
  # config.redis_connection = Redis.new(
  #   url: ENV['REDIS_URL'],
  #   timeout: 1,
  #   reconnect_attempts: 2
  # )

  # Configure Memcached connection (required if using Memcached store)
  # config.memcached_connection = Dalli::Client.new(
  #   ENV['MEMCACHED_URL'],
  #   { expires_in: 1.day, compress: true }
  # )

  # Configure logging (set to nil to disable logging)
  # config.logger = Rails.logger

  # Configure default handler for controllers (HTTP requests)
  # config.handle_controller_exceeded = -> {
  #   render json: {
  #     error: "Too many requests",
  #     retry_after: response.headers["Retry-After"]
  #   }, status: :too_many_requests
  # }

  # Configure default handler for methods
  # By default, it raises RailsRateLimit::RateLimitExceeded
  # config.handle_klass_exceeded = -> {
  #   raise RailsRateLimit::RateLimitExceeded, "Rate limit exceeded"
  # }
end
