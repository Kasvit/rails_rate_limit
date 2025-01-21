# frozen_string_literal: true

module RailsRateLimit
  module Klass
    extend ActiveSupport::Concern

    class_methods do
      def set_rate_limit(method_name, limit:, period:, by: nil, store: nil, on_exceeded: nil)
        Validations.validate_options!(limit: limit, period: period, by: by, store: store)

        if method_defined?(method_name) || private_method_defined?(method_name)
          set_instance_rate_limit(method_name, limit: limit, period: period, by: by, store: store,
                                               on_exceeded: on_exceeded)
        elsif singleton_class.method_defined?(method_name) || singleton_class.private_method_defined?(method_name)
          set_class_rate_limit(method_name, limit: limit, period: period, by: by, store: store,
                                            on_exceeded: on_exceeded)
        else
          raise ArgumentError, "Method #{method_name} is not defined"
        end
      end

      def set_instance_rate_limit(method_name, limit:, period:, by:, store:, on_exceeded:)
        original_method = instance_method(method_name)

        define_method(method_name) do |*args, &block|
          limiter = RateLimiter.new(
            context: self,
            by: by || lambda {
              "#{self.class.name}##{method_name}:#{respond_to?(:id) ? "id=#{id}" : "object_id=#{object_id}"}"
            },
            limit: limit,
            period: period.to_i,
            store: store
          )

          begin
            limiter.perform!
            original_method.bind(self).call(*args, &block)
          rescue RailsRateLimit::RateLimitExceeded
            handler = on_exceeded.nil? ? RailsRateLimit.configuration.handle_klass_exceeded : on_exceeded
            instance_exec(&handler)
          end
        end
      end

      def set_class_rate_limit(method_name, limit:, period:, by:, store:, on_exceeded:)
        original_method = singleton_class.instance_method(method_name)

        singleton_class.define_method(method_name) do |*args, &block|
          limiter = RateLimiter.new(
            context: self,
            by: by || lambda {
              "#{name}.#{method_name}"
            },
            limit: limit,
            period: period.to_i,
            store: store
          )

          begin
            limiter.perform!
            original_method.bind(self).call(*args, &block)
          rescue RailsRateLimit::RateLimitExceeded
            handler = on_exceeded.nil? ? RailsRateLimit.configuration.handle_klass_exceeded : on_exceeded
            instance_exec(&handler)
          end
        end
      end
    end
  end
end
