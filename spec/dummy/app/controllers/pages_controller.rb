# frozen_string_literal: true

class PagesController < ApplicationController
  include RailsRateLimit::Controller

  set_rate_limit limit: 5,
                 period: 1.minute

  def about
    render json: { message: "Hello from rate-limited action!" }
  end
end
