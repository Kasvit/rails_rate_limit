# frozen_string_literal: true

module RailsRateLimit
  module Stores
    class Redis < Base
      def initialize
        @redis = RailsRateLimit.configuration.redis_connection
        raise "Redis connection not configured" unless @redis
      end

      def count_requests(key, period)
        now = Time.now.to_f
        min_time = now - period
        key = cache_key(key)

        @redis.multi do |redis|
          redis.zremrangebyscore(key, 0, min_time)
          redis.zcard(key)
        end.last
      rescue StandardError => e
        RailsRateLimit.logger&.error("RailsRateLimit::Stores::Redis#count_requests error: #{e.message}")
        0
      end

      def record_request(key, period)
        now = Time.now.to_f
        key = cache_key(key)

        @redis.multi do |redis|
          redis.zadd(key, now, now)
          redis.expire(key, period)
        end
      rescue StandardError => e
        RailsRateLimit.logger&.error("RailsRateLimit::Stores::Redis#record_request error: #{e.message}")
      end
    end
  end
end
