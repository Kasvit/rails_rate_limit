# frozen_string_literal: true

# lib/rails_rate_limit/configuration.rb
module RailsRateLimit
  class Configuration
    attr_reader :default_store, :redis_connection, :memcached_connection, :logger,
                :default_on_controller_exceeded, :default_on_method_exceeded

    def initialize
      @default_store = :redis
      @redis_connection = nil
      @memcached_connection = nil
      @logger = nil
      set_default_handlers
    end

    def default_store=(value)
      @default_store = value
    end

    def redis_connection=(value)
      @redis_connection = value
    end

    def memcached_connection=(value)
      @memcached_connection = value
    end

    def logger=(value)
      @logger = value
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
      @default_on_controller_exceeded = lambda do |controller|
        controller.render json: {
          error: "Too many requests",
          retry_after: controller.response.headers["Retry-After"]
        }, status: :too_many_requests
      end

      @default_on_method_exceeded = -> { nil }
    end
  end
end

