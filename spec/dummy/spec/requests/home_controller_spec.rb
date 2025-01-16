# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe HomeController, type: :request do
  describe "GET /index" do
    %i[memory redis memcached].each do |store|
      context "with #{store} store" do
        before do
          RailsRateLimit.configuration.default_store = store
          case store
          when :memory
            RailsRateLimit::Stores::Memory.instance.clear
          when :redis
            RailsRateLimit.configuration.redis_connection.flushdb
          when :memcached
            RailsRateLimit.configuration.memcached_connection.flush
          end
        end

        it "returns success response" do
          get root_path
          expect(response).to have_http_status(:success)
        end

        it "limits requests" do
          5.times { get root_path }

          get root_path
          expect(response).to have_http_status(:too_many_requests)
        end
      end
    end
  end

  describe "GET /send_notification" do
    %i[memory redis memcached].each do |store|
      context "with #{store} store" do
        before do
          RailsRateLimit.configuration.default_store = store
          case store
          when :memory
            RailsRateLimit::Stores::Memory.instance.clear
          when :redis
            RailsRateLimit.configuration.redis_connection.flushdb
          when :memcached
            RailsRateLimit.configuration.memcached_connection.flush
          end
        end

        it "delivers notification successfully" do
          get send_notification_path
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)["message"]).to include("delivered")
        end

        it "limits notification delivery" do
          3.times { get send_notification_path }

          get send_notification_path
          expect(response).to have_http_status(:too_many_requests)
        end
      end
    end
  end

  describe "GET /generate_report" do
    %i[memory redis memcached].each do |store|
      context "with #{store} store" do
        before do
          RailsRateLimit.configuration.default_store = store
          case store
          when :memory
            RailsRateLimit::Stores::Memory.instance.clear
          when :redis
            RailsRateLimit.configuration.redis_connection.flushdb
          when :memcached
            RailsRateLimit.configuration.memcached_connection.flush
          end
        end

        it "generates report successfully" do
          get generate_report_path(type: "sales")
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)["message"]).to include("Generated sales report")
        end

        it "limits report generation" do
          2.times { get generate_report_path(type: "sales") }

          get generate_report_path(type: "sales")
          expect(response).to have_http_status(:too_many_requests)
        end

        it "tracks limits separately for different report types" do
          2.times { get generate_report_path(type: "sales") }

          get generate_report_path(type: "inventory")
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
