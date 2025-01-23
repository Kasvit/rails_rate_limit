# frozen_string_literal: true

Rails.application.routes.draw do
  get "/about", to: "pages#about"
  get "/unlimited", to: "pages#unlimited"
  root "home#index"

  get "send_notification", to: "home#send_notification"
  get "generate_report", to: "home#generate_report"
end
