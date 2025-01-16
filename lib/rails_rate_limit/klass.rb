# frozen_string_literal: true

module RailsRateLimit
  module Klass
    extend ActiveSupport::Concern

    class_methods do
      def set_rate_limit(method_name, limit:, period:, by: nil, store: nil, on_exceeded: nil)
        Validations.validate_options!(limit: limit, period: period, by: by, store: store)

        original_method = instance_method(method_name)

        define_method(method_name) do |*args, &block|
          limiter = RateLimiter.new(
            context: self,
            by: by || -> { "#{self.class.name}:#{respond_to?(:id) ? id : object_id}" },
            limit: limit,
            period: period.to_i,
            store: store
          )

          begin
            limiter.perform!
            original_method.bind(self).call(*args, &block)
          rescue RailsRateLimit::RateLimitExceeded
            handler = on_exceeded || RailsRateLimit.configuration.default_on_method_exceeded
            instance_exec(&handler)
            nil
          end
        end
      end
    end
  end
end
