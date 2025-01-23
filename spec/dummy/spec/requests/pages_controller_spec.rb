# frozen_string_literal: true

require "rails_helper"
require "timecop"

RSpec.describe "PagesController", type: :request do
  before do
    Redis.new.flushdb
    Dalli::Client.new.flush
    RailsRateLimit::Stores::Memory.instance.clear
  end

  after do
    Timecop.return
  end

  %i[memory redis memcached].each do |store_type|
    context "with #{store_type} store" do
      before do
        RailsRateLimit.configure do |config|
          config.default_store = store_type
        end
      end

      describe "GET /about" do
        it "returns success response" do
          get "/about"
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)).to eq("message" => "Hello from rate-limited action!")
        end

        it "returns too_many_requests when local rate limit exceeded" do
          5.times { get "/about" }
          get "/about"
          expect(response).to have_http_status(:too_many_requests)
          expect(JSON.parse(response.body)).to include("error" => "Too many requests")
        end

        it "returns too_many_requests when global rate limit exceeded" do
          100.times { get "/about" }
          get "/about"
          expect(response).to have_http_status(:too_many_requests)
          expect(JSON.parse(response.body)).to include("error" => "Too many requests")
        end
      end

      describe "GET /unlimited" do
        it "returns success response" do
          get "/unlimited"
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)).to eq("message" => "This action only has local rate limit!")
        end

        it "returns too_many_requests when local rate limit exceeded" do
          5.times { get "/unlimited" }
          get "/unlimited"
          expect(response).to have_http_status(:too_many_requests)
          expect(JSON.parse(response.body)).to include("error" => "Too many requests")
        end

        it "ignores global rate limit but respects local" do
          3.times do
            get "/unlimited"
            expect(response).to have_http_status(:success)
          end

          Timecop.travel(Time.now + 61.seconds)

          3.times do
            get "/unlimited"
            expect(response).to have_http_status(:success)
          end

          get "/unlimited"
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
