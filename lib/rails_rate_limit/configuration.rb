# frozen_string_literal: true

# lib/rails_rate_limit/configuration.rb
module RailsRateLimit
  class Configuration
    attr_accessor :default_store, :redis_connection, :memcached_connection, :logger
    attr_reader :default_response

    def initialize
      @default_store = :redis
      @redis_connection = nil
      @memcached_connection = nil
      @logger = nil
      set_default_response
    end

    def default_response=(handler)
      raise ArgumentError, "default_response must be a Proc" unless handler.is_a?(Proc)

      @default_response = handler
    end

    private

    def set_default_response
      @default_response = lambda {
        render json: {
          error: "Too many requests",
          retry_after: response.headers["Retry-After"]
        }, status: :too_many_requests
      }
    end
  end
end
