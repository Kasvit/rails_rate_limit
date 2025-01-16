# frozen_string_literal: true

require "active_support/concern"

module RailsRateLimit
  module Controller
    extend ActiveSupport::Concern

    class_methods do
      def controller_rate_limit(limit:, period:, by: nil, response: nil, store: nil, **options)
        Validations.validate_options!(limit: limit, period: period, by: by, response: response, store: store)

        before_action(options) do |controller|
          limiter = RateLimiter.new(
            context: controller,
            by: by,
            limit: limit,
            period: period.to_i,
            store: store
          )

          begin
            limiter.perform!
          rescue RailsRateLimit::RateLimitExceeded
            handler = response || RailsRateLimit.configuration.default_response
            controller.instance_exec(&handler)
            false
          end
        end
      end
    end
  end
end
