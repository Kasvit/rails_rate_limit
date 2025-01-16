# frozen_string_literal: true

module RailsRateLimit
  module Stores
    class Memcached < Base
      def initialize
        @memcached = RailsRateLimit.configuration.memcached_connection
        raise "Memcached connection not configured" unless @memcached
      end

      def count_requests(key, period)
        now = current_time
        min_time = now - period
        key = cache_key(key)

        timestamps = get_timestamps(key)
        valid_timestamps = cleanup_old_requests(timestamps, min_time)

        count = valid_timestamps.size

        if valid_timestamps.empty?
          begin
            @memcached.delete(key)
          rescue StandardError
            nil
          end
          0
        else
          begin
            @memcached.set(key, valid_timestamps, period)
          rescue StandardError
            nil
          end
          count
        end
      rescue StandardError => e
        RailsRateLimit.logger&.error("RailsRateLimit::Stores::Memcached#count_requests error: #{e.message}")
        0
      end

      def record_request(key, period)
        now = current_time
        min_time = now - period
        key = cache_key(key)

        timestamps = get_timestamps(key)
        timestamps = cleanup_old_requests(timestamps, min_time)
        timestamps << now
        count = timestamps.size

        begin
          @memcached.set(key, timestamps, period)
        rescue StandardError
          nil
        end
        count
      rescue StandardError => e
        RailsRateLimit.logger&.error("RailsRateLimit::Stores::Memcached#record_request error: #{e.message}")
        0
      end

      private

      def get_timestamps(key)
        @memcached.get(key) || []
      rescue StandardError => e
        RailsRateLimit.logger&.error("RailsRateLimit::Stores::Memcached#get_timestamps error: #{e.message}")
        []
      end

      def cleanup_old_requests(timestamps, min_time)
        timestamps.reject { |timestamp| timestamp < min_time }
      end

      def current_time
        Time.now.to_f
      end
    end
  end
end
