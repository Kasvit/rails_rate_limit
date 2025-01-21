# frozen_string_literal: true

require "rails_helper"

RSpec.describe "HomeController", type: :request do
  before do
    Redis.new.flushdb
    Dalli::Client.new.flush
    RailsRateLimit::Stores::Memory.instance.clear
  end

  %i[memory redis memcached].each do |store_type|
    context "with #{store_type} store" do
      before do
        RailsRateLimit.configure do |config|
          config.default_store = store_type
        end
      end

      describe "GET /index" do
        it "returns success response" do
          get "/"
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)).to eq("message" => "Hello from rate-limited action!")
        end

        it "returns too_many_requests when rate limit exceeded" do
          5.times { get "/" }
          get "/"
          expect(response).to have_http_status(:too_many_requests)
          expect(JSON.parse(response.body)).to include("error" => "Too many requests")
        end

        it "adds rate limit headers" do
          get "/"
          expect(response.headers).to include(
            "X-RateLimit-Limit",
            "X-RateLimit-Remaining",
            "X-RateLimit-Reset"
          )
        end
      end

      describe "GET /send_notification" do
        let!(:notification) { Notification.create }

        it "returns success response" do
          get "/send_notification"
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)["message"]).to include("delivered")
        end

        it "returns error when notification rate limit exceeded" do
          notification = Notification.create
          3.times { notification.safe_deliver }
          get "/send_notification"
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to include("error" => "Failed to deliver notification")
        end

        it "returns too_many_requests when controller rate limit exceeded" do
          5.times { get "/send_notification" }
          get "/send_notification"
          expect(response).to have_http_status(:too_many_requests)
          expect(JSON.parse(response.body)).to include("error" => "Too many requests")
        end
      end

      describe "GET /generate_report" do
        let(:organization_id) { 1 }

        it "returns success response" do
          get "/generate_report", params: { organization_id: organization_id }
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)["message"]).to include("generated")
        end

        it "returns error when report rate limit exceeded" do
          2.times { ReportGenerator.safe_generate(organization_id) }
          get "/generate_report", params: { organization_id: organization_id }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to include("error" => "Failed to generate report")
        end

        it "returns too_many_requests when controller rate limit exceeded" do
          5.times { get "/generate_report", params: { organization_id: organization_id } }
          get "/generate_report", params: { organization_id: organization_id }
          expect(response).to have_http_status(:too_many_requests)
          expect(JSON.parse(response.body)).to include("error" => "Too many requests")
        end

        it "tracks limits separately for different organizations" do
          2.times { ReportGenerator.safe_generate(organization_id) }
          get "/generate_report", params: { organization_id: organization_id + 1 }
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
