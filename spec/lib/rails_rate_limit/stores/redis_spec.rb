# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Stores::Redis do
  let(:redis_store) { described_class.new }
  let(:key) { "test_key" }
  let(:period) { 60 }

  before do
    # Очищаємо Redis перед кожним тестом
    Redis.new.flushdb
  end

  describe "#count_requests" do
    context "when successful" do
      before do
        5.times { redis_store.record_request(key, period) }
      end

      it "returns the count of requests" do
        expect(redis_store.count_requests(key, period)).to eq(5)
      end

      it "removes expired requests" do
        Timecop.travel(Time.now + period + 1) do
          expect(redis_store.count_requests(key, period)).to eq(0)
        end
      end
    end

    context "when redis raises error" do
      before do
        allow(redis_store.instance_variable_get(:@redis)).to receive(:multi).and_raise(Redis::ConnectionError)
      end

      it "returns 0 and logs error" do
        logger = double("Logger")
        allow(RailsRateLimit).to receive(:logger).and_return(logger)
        expect(logger).to receive(:error).with(/RailsRateLimit::Stores::Redis#count_requests error:/)

        expect(redis_store.count_requests(key, period)).to eq(0)
      end
    end
  end

  describe "#record_request" do
    context "when successful" do
      it "adds request to sorted set" do
        expect do
          redis_store.record_request(key, period)
        end.to change { redis_store.count_requests(key, period) }.by(1)
      end
    end

    context "when redis raises error" do
      before do
        allow(redis_store.instance_variable_get(:@redis)).to receive(:multi).and_raise(Redis::ConnectionError)
      end

      it "logs error" do
        logger = double("Logger")
        allow(RailsRateLimit).to receive(:logger).and_return(logger)
        expect(logger).to receive(:error).with(/RailsRateLimit::Stores::Redis#record_request error:/)

        redis_store.record_request(key, period)
      end
    end
  end

  context "when redis is not configured" do
    before do
      allow(RailsRateLimit.configuration).to receive(:redis_connection).and_return(nil)
    end

    it "raises an error" do
      expect { described_class.new }.to raise_error("Redis connection not configured")
    end
  end
end
