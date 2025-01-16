# frozen_string_literal: true

module RailsRateLimit
  module Validations
    class << self
      def validate_options!(options)
        validate_limit!(options[:limit])
        validate_period!(options[:period])
        validate_by!(options[:by]) if options[:by]
        validate_on_exceeded!(options[:on_exceeded]) if options[:on_exceeded]
        validate_store!(options[:store]) if options[:store]
      end

      private

      def validate_limit!(limit)
        case limit
        when Numeric
          raise ArgumentError, "limit must be positive" unless limit.positive?
        when Proc
          # Will be evaluated at runtime
        else
          raise ArgumentError, "limit must be a number or Proc"
        end
      end

      def validate_period!(period)
        return if period.is_a?(Integer) && period.positive?

        raise ArgumentError, "period must be a positive integer (seconds)"
      end

      def validate_by!(by)
        return if by.is_a?(String) || by.is_a?(Proc)

        raise ArgumentError, "by must be a String or Proc"
      end

      def validate_on_exceeded!(on_exceeded)
        return if on_exceeded.is_a?(Proc)

        raise ArgumentError, "on_exceeded must be a Proc"
      end

      def validate_store!(store)
        return if %i[redis memory memcached].include?(store.to_sym)

        raise ArgumentError, "unsupported store: #{store}"
      end
    end
  end
end
