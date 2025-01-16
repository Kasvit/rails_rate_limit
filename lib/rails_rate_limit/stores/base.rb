# frozen_string_literal: true

module RailsRateLimit
  module Stores
    class Base
      def self.resolve(store_name)
        case store_name.to_sym
        when :redis
          Redis.new
        when :memory
          Memory.instance
        when :memcached
          Memcached.new
        else
          raise StoreError, "Unsupported store: #{store_name}"
        end
      end

      def count_requests(key, period)
        raise NotImplementedError
      end

      def record_request(key, period)
        raise NotImplementedError
      end

      private

      def cache_key(key)
        "rate_limit:#{key}"
      end
    end
  end
end
