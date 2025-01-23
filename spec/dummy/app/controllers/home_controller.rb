# frozen_string_literal: true

class HomeController < ApplicationController
  set_rate_limit limit: 5,
                 period: 1.minute

  def index
    render json: { message: "Hello from rate-limited action!" }
  end

  def send_notification
    notification = Notification.last || Notification.create
    result = notification.safe_deliver

    if result
      render json: { message: result }
    else
      render json: { error: "Failed to deliver notification" }, status: :unprocessable_entity
    end
  end

  def generate_report
    organization_id = params[:organization_id] || 1
    result = ReportGenerator.safe_generate(organization_id)

    if result
      render json: { message: result }
    else
      render json: { error: "Failed to generate report" }, status: :unprocessable_entity
    end
  end
end
