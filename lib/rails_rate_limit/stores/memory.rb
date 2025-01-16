# frozen_string_literal: true

module RailsRateLimit
  module Stores
    class Memory < Base
      class << self
        def instance
          @instance ||= new
        end
      end

      def initialize
        @store = {}
        @mutex = Mutex.new
      end

      def count_requests(key, period)
        now = current_time
        min_time = now - period
        key = cache_key(key)

        @mutex.synchronize do
          cleanup_old_requests(key, min_time)
          @store[key]&.size || 0
        end
      rescue StandardError => e
        RailsRateLimit.logger&.error("RailsRateLimit::Stores::Memory#count_requests error: #{e.message}")
        0
      end

      def record_request(key, period)
        now = current_time
        min_time = now - period
        key = cache_key(key)

        @mutex.synchronize do
          cleanup_old_requests(key, min_time)
          @store[key] ||= []
          @store[key] << now
          @store[key].size
        end
      rescue StandardError => e
        RailsRateLimit.logger&.error("RailsRateLimit::Stores::Memory#record_request error: #{e.message}")
        0
      end

      def clear
        @mutex.synchronize do
          @store.clear
        end
      end

      private

      def cleanup_old_requests(key, min_time)
        return unless @store[key]

        @store[key].reject! { |timestamp| timestamp < min_time }
        @store.delete(key) if @store[key].empty?
      end

      def current_time
        Time.now.to_f
      end
    end
  end
end
