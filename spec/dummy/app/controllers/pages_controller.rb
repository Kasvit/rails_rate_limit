# frozen_string_literal: true

class PagesController < ApplicationController
  set_rate_limit limit: 5,
                 period: 1.minute

  skip_before_action :global_rate_limit, only: [:unlimited]

  def about
    render json: { message: "Hello from rate-limited action!" }
  end

  def unlimited
    render json: { message: "This action only has local rate limit!" }
  end
end
