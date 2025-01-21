# frozen_string_literal: true

require "active_support/concern"

module RailsRateLimit
  module Controller
    extend ActiveSupport::Concern

    class_methods do
      def set_rate_limit(limit:, period:, by: nil, on_exceeded: nil, store: nil, **options)
        Validations.validate_options!(limit: limit, period: period, by: by, on_exceeded: on_exceeded, store: store)

        before_action(options) do |controller|
          limiter = RateLimiter.new(
            context: controller,
            by: by || "#{controller.class.name}:#{controller.request.remote_ip}",
            limit: limit,
            period: period.to_i,
            store: store
          )

          begin
            limiter.perform!
          rescue RailsRateLimit::RateLimitExceeded
            handler = on_exceeded.nil? ? RailsRateLimit.configuration.handle_controller_exceeded : on_exceeded
            controller.instance_exec(&handler)
          end
        end
      end
    end
  end
end
