# frozen_string_literal: true

require "active_support/concern"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/class/attribute"

module RailsRateLimit
  module Controller
    extend ActiveSupport::Concern

    included do
      class_attribute :rate_limits, default: []
      class_attribute :skipped_rate_limits, default: []
    end

    class_methods do
      def set_rate_limit(limit:, period:, by: nil, on_exceeded: nil, store: nil, **options)
        Validations.validate_options!(limit: limit, period: period, by: by, on_exceeded: on_exceeded, store: store)

        callback_name = options.delete(:as) || :"check_rate_limit_#{name.to_s.underscore}_#{rate_limits.length}"

        self.rate_limits = rate_limits + [{
          limit: limit,
          period: period,
          by: by,
          on_exceeded: on_exceeded,
          store: store,
          callback_name: callback_name
        }]

        define_method(callback_name) do
          self.class.rate_limits.each do |rate_limit|
            next if self.class.skipped_rate_limits.include?(rate_limit[:callback_name])

            limiter = RateLimiter.new(
              context: self,
              by: rate_limit[:by] || "#{self.class.name}:#{request.remote_ip}",
              limit: rate_limit[:limit],
              period: rate_limit[:period].to_i,
              store: rate_limit[:store]
            )

            begin
              limiter.perform!
            rescue RailsRateLimit::RateLimitExceeded
              handler = rate_limit[:on_exceeded].nil? ? RailsRateLimit.configuration.handle_controller_exceeded : rate_limit[:on_exceeded]
              return instance_exec(&handler)
            end
          end
        end

        before_action callback_name, **options
      end

      def skip_before_action(callback_name, **options)
        super
        self.skipped_rate_limits = skipped_rate_limits + [callback_name]
      end

      def inherited(subclass)
        super
        subclass.rate_limits = rate_limits.dup
        subclass.skipped_rate_limits = skipped_rate_limits.dup
      end
    end
  end
end
