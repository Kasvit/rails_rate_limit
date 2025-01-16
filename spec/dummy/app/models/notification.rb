# frozen_string_literal: true

class Notification < ApplicationRecord
  include RailsRateLimit::Klass

  def deliver
    update(delivered_at: Time.now)
    "Notification #{id} delivered"
  end

  def on_exceeded
    puts "Rate limit exceeded for notifications"
    nil
  end

  set_rate_limit :deliver,
                 limit: 3,
                 period: 1.minute,
                 by: -> { "notification:#{id}" },
                 on_exceeded: -> { on_exceeded }
end
