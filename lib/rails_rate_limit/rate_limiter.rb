# frozen_string_literal: true

module RailsRateLimit
  class RateLimiter
    attr_reader :remaining_requests, :reset_time

    def initialize(context:, by:, limit:, period:, store:)
      @context = context
      @by = by
      @limit = limit
      @period = period
      @store_name = store || RailsRateLimit.configuration.default_store

      validate_runtime_values!

      @store = resolve_store
      @key = resolve_key
      @limit_value = resolve_limit
      setup_monitoring
    end

    def perform!
      if rate_limit_exceeded?
        log_rate_limit_exceeded
        add_rate_limit_headers
        raise RateLimitExceeded
      end

      record_request
      add_rate_limit_headers
      true
    end

    private

    attr_reader :context, :by, :limit, :period, :store, :key, :limit_value, :store_name

    def validate_runtime_values!
      limit_value = @limit.is_a?(Proc) ? context.instance_exec(&@limit) : @limit

      unless limit_value.is_a?(Integer) && limit_value.positive?
        raise ArgumentError, "Limit must evaluate to a positive integer, got: #{limit_value}"
      end

      return if @period.positive?

      raise ArgumentError, "Period must be positive, got: #{@period}"
    end

    def resolve_key
      by.is_a?(Proc) ? context.instance_exec(&by) : by
    end

    def resolve_limit
      limit.is_a?(Proc) ? context.instance_exec(&limit) : limit
    end

    def resolve_store
      Stores::Base.resolve(store_name)
    end

    def rate_limit_exceeded?
      current_count = store.count_requests(cache_key, period)
      @remaining_requests = [limit_value - current_count, 0].max
      @reset_time = Time.now + period
      current_count >= limit_value
    end

    def record_request
      store.record_request(cache_key, period)
    end

    def cache_key
      @cache_key ||= "rate_limit:#{key}"
    end

    def add_rate_limit_headers
      return unless context.respond_to?(:response)

      context.response.headers["X-RateLimit-Limit"] = limit_value.to_s
      context.response.headers["X-RateLimit-Remaining"] = remaining_requests.to_s
      context.response.headers["X-RateLimit-Reset"] = reset_time.to_i.to_s
      context.response.headers["Retry-After"] = period.to_s if remaining_requests.zero?
    end

    def setup_monitoring
      @monitor = Monitoring.new(
        logger: RailsRateLimit.configuration.logger
      )
    end

    def log_rate_limit_exceeded
      @monitor.log_exceeded(
        key: key,
        limit: limit_value,
        period: period
      )
    end
  end
end
