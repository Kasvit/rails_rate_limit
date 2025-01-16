# frozen_string_literal: true

class HomeController < ApplicationController
  include RailsRateLimit::Controller

  set_rate_limit limit: 5,
                 period: 1.minute,
                 only: :index

  def index
    render json: { message: "Hello from rate-limited action!" }
  end

  def send_notification
    notification = Notification.first_or_create!
    message = notification.deliver

    if message
      render json: { message: message }
    else
      render json: { error: "Rate limit exceeded for notifications" }, status: :too_many_requests
    end
  end

  def generate_report
    generator = ReportGenerator.new(params[:type] || "default")
    message = generator.generate

    if message
      render json: { message: message }
    else
      render json: { error: "Rate limit exceeded for reports" }, status: :too_many_requests
    end
  end
end
