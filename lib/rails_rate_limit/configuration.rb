# frozen_string_literal: true

# lib/rails_rate_limit/configuration.rb
module RailsRateLimit
  class Configuration
    attr_accessor :default_store, :redis_connection, :memcached_connection, :logger
    attr_reader :handle_controller_exceeded, :handle_klass_exceeded

    def initialize
      @default_store = :memory
      @redis_connection = nil
      @memcached_connection = nil
      @logger = nil
      set_default_handlers
    end

    def handle_controller_exceeded=(handler)
      raise ArgumentError, "handle_controller_exceeded must be a Proc" unless handler.is_a?(Proc)

      @handle_controller_exceeded = handler
    end

    def handle_klass_exceeded=(handler)
      raise ArgumentError, "handle_klass_exceeded must be a Proc" unless handler.is_a?(Proc)

      @handle_klass_exceeded = handler
    end

    private

    def set_default_handlers
      @handle_controller_exceeded = lambda {
        render json: {
          error: "Too many requests"
        }, status: :too_many_requests
      }

      @handle_klass_exceeded = lambda {
        raise RailsRateLimit::RateLimitExceeded, "Rate limit exceeded"
      }
    end
  end
end
