# frozen_string_literal: true

module RailsRateLimit
  class Monitoring
    def initialize(logger:)
      @logger = logger
    end

    def log_exceeded(key:, limit:, period:)
      return unless @logger

      @logger.warn(
        "Rate limit exceeded for #{key}. " \
        "Limit: #{limit} requests per #{period} seconds"
      )
    end
  end
end
