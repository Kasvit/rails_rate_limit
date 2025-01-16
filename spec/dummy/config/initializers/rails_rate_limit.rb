# frozen_string_literal: true

# RailsRateLimit.configure do |config|
#   config.default_store = :redis
#   config.redis_connection = Redis.new(url: 'redis://localhost:6379/0')
#   config.logger = Rails.logger
#   config.default_response = -> {
#     redirect_to root_path, alert: 'Too many requests'
#   }

# Simple default response
# config.default_response = -> { head :too_many_requests }

# Or more detailed response
# config.default_response = -> {
#   render json: {
#     error: 'Rate limit exceeded',
#     retry_after: response.headers["Retry-After"]
#   }, status: 429
# }
# end

RailsRateLimit.configure do |config|
  # Вибір сховища даних (:redis, :memory, або :memcached)
  config.default_store = :memory

  # Налаштування підключення до Redis (якщо використовуєте Redis)
  config.redis_connection = Redis.new(url: "redis://localhost:6379/0")

  # АБО налаштування Memcached (якщо використовуєте Memcached)
  config.memcached_connection = Dalli::Client.new("localhost:11211")

  # Налаштування логування
  config.logger = Rails.logger

  # Користувацька відповідь за замовчуванням
  config.default_response = lambda {
    render json: {
      error: "Перевищено ліміт запитів",
      retry_after: response.headers["Retry-After"]
    }, status: :too_many_requests
  }
end
