# frozen_string_literal: true

# lib/rails_rate_limit/configuration.rb
module RailsRateLimit
  class Configuration
    attr_accessor :default_store, :redis_connection, :memcached_connection, :logger
    attr_reader :default_on_controller_exceeded, :default_on_method_exceeded

    def initialize
      @default_store = :redis
      @redis_connection = nil
      @memcached_connection = nil
      @logger = nil
      set_default_handlers
    end

    def default_on_controller_exceeded=(handler)
      raise ArgumentError, "default_on_controller_exceeded must be a Proc" unless handler.is_a?(Proc)

      @default_on_controller_exceeded = handler
    end

    def default_on_method_exceeded=(handler)
      raise ArgumentError, "default_on_method_exceeded must be a Proc" unless handler.is_a?(Proc)

      @default_on_method_exceeded = handler
    end

    private

    def set_default_handlers
      @default_on_controller_exceeded = lambda {
        render json: {
          error: "Too many requests",
          retry_after: response.headers["Retry-After"]
        }, status: :too_many_requests
      }

      @default_on_method_exceeded = -> { nil }
    end
  end
end
