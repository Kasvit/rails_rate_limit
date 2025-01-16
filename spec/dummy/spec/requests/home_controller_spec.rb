# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe HomeController, type: :controller do
  describe "GET #index" do
    before(:all) do
      RailsRateLimit.configure do |config|
        config.logger = Logger.new($stdout)
        config.logger.level = Logger::DEBUG
      end
    end

    describe "when store to redis" do
      before do
        allow_any_instance_of(HomeController).to receive(:rate_by).and_return("test_user")
        allow_any_instance_of(HomeController).to receive(:limit).and_return(2)
        RailsRateLimit.configure do |config|
          config.default_store = :redis
          config.redis_connection = Redis.new
        end
      end

      it "returns a too many requests response" do
        2.times do
          get :index
          expect(response).to have_http_status(:ok)
          Timecop.travel(5.seconds.from_now)
        end

        get :index # 3rd request
        expect(response).to have_http_status(:too_many_requests)

        Timecop.travel(20.seconds.from_now)
        get :index # should work as first request expired
        expect(response).to have_http_status(:ok)

        get :index # should fail again
        expect(response).to have_http_status(:too_many_requests)
      end
    end

    describe "when store to memory" do
      before do
        allow_any_instance_of(HomeController).to receive(:rate_by).and_return("test_user")
        allow_any_instance_of(HomeController).to receive(:limit).and_return(2)
        RailsRateLimit.configure do |config|
          config.default_store = :memory
        end
      end

      it "returns a too many requests response" do
        2.times do |i|
          get :index
          expect(response).to have_http_status(:ok), "Failed on request #{i + 1}"
          Timecop.travel(5.seconds.from_now)
        end

        get :index # 3rd request
        expect(response).to have_http_status(:too_many_requests), "Failed on 3rd request"

        Timecop.travel(20.seconds.from_now)
        get :index # should work as first request expired
        expect(response).to have_http_status(:ok), "Failed after time travel"

        get :index # should fail again
        expect(response).to have_http_status(:too_many_requests), "Failed on last request"
      end
    end

    describe "when store to memcached" do
      before do
        allow_any_instance_of(HomeController).to receive(:rate_by).and_return("test_user")
        allow_any_instance_of(HomeController).to receive(:limit).and_return(2)
        RailsRateLimit.configure do |config|
          config.default_store = :memcached
          config.memcached_connection = Dalli::Client.new("localhost:11211")
        end
      end

      it "returns a too many requests response" do
        2.times do
          get :index
          expect(response).to have_http_status(:ok)
          Timecop.travel(5.seconds.from_now)
        end

        get :index # 3rd request
        expect(response).to have_http_status(:too_many_requests)

        Timecop.travel(20.seconds.from_now)
        get :index # should work as first request expired
        expect(response).to have_http_status(:ok)

        get :index # should fail again
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end
end
