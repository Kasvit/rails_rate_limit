# frozen_string_literal: true

class HomeController < ApplicationController
  include RailsRateLimit::Controller

  controller_rate_limit limit: -> { limit },
                        period: 30.seconds.to_i,
                        by: -> { rate_by },
                        response: -> { rate_limit_exceeded }

  def index
    render json: { message: "hello world" }, status: :ok
  end

  private

  def limit
    3
  end

  def rate_by
    "test_user"
  end

  def rate_limit_exceeded
    render json: { message: "Rate limit exceeded" }, status: :too_many_requests
  end
end
