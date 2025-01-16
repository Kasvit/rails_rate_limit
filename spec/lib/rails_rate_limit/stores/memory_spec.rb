# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Stores::Memory do
  let(:store) { described_class.instance }
  let(:key) { "test_key" }
  let(:period) { 30 }
  let(:cache_key) { "rate_limit:#{key}" }

  before do
    store.clear
  end

  describe ".instance" do
    it "returns the same instance" do
      expect(described_class.instance).to eq(described_class.instance)
    end
  end

  describe "#count_requests" do
    it "returns 0 for non-existent key" do
      expect(store.count_requests(key, period)).to eq(0)
    end

    it "returns correct count for existing requests" do
      now = Time.now.to_f
      Timecop.freeze(now) do
        store.record_request(key, period)
        store.record_request(key, period)
        expect(store.count_requests(key, period)).to eq(2)
      end
    end

    it "removes expired requests" do
      now = Time.now.to_f
      Timecop.freeze(now) do
        store.record_request(key, period)
      end

      Timecop.freeze(now + period + 1) do
        expect(store.count_requests(key, period)).to eq(0)
      end
    end
  end

  describe "#record_request" do
    it "increments request count" do
      now = Time.now.to_f
      Timecop.freeze(now) do
        expect do
          store.record_request(key, period)
        end.to change { store.count_requests(key, period) }.by(1)
      end
    end

    it "returns current count" do
      now = Time.now.to_f
      Timecop.freeze(now) do
        expect(store.record_request(key, period)).to eq(1)
        expect(store.record_request(key, period)).to eq(2)
      end
    end
  end

  describe "#clear" do
    it "removes all stored data" do
      store.record_request(key, period)
      store.clear
      expect(store.count_requests(key, period)).to eq(0)
    end
  end

  context "thread safety" do
    it "handles concurrent requests" do
      now = Time.now.to_f
      Timecop.freeze(now) do
        threads = 10.times.map do
          Thread.new do
            store.record_request(key, period)
          end
        end
        threads.each(&:join)

        expect(store.count_requests(key, period)).to eq(10)
      end
    end
  end
end
