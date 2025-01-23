# frozen_string_literal: true

class ApplicationController < ActionController::API
  include RailsRateLimit::Controller

  set_rate_limit limit: 100, period: 1.minute, as: :global_rate_limit
end
