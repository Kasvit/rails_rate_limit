# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Stores::Memcached do
  let(:memcached) { double("Memcached") }
  let(:store) { described_class.new }
  let(:key) { "test_key" }
  let(:period) { 30 }
  let(:cache_key) { "rate_limit:#{key}" }

  before do
    allow(RailsRateLimit.configuration).to receive(:memcached_connection).and_return(memcached)
    allow(memcached).to receive(:flush)
    allow(memcached).to receive(:delete)
  end

  describe "#count_requests" do
    it "returns 0 for non-existent key" do
      allow(memcached).to receive(:get).with(cache_key).and_return(nil)
      expect(store.count_requests(key, period)).to eq(0)
    end

    it "returns correct count for existing requests" do
      now = Time.now.to_f
      timestamps = [now, now]
      allow(memcached).to receive(:get).with(cache_key).and_return(timestamps)
      allow(memcached).to receive(:set)
      expect(store.count_requests(key, period)).to eq(2)
    end

    it "removes expired requests" do
      now = Time.now
      timestamps = [now.to_f - period - 2]
      allow(memcached).to receive(:get).with(cache_key).and_return(timestamps)
      allow(memcached).to receive(:delete)

      Timecop.freeze(now) do
        expect(store.count_requests(key, period)).to eq(0)
      end
    end
  end

  describe "#record_request" do
    it "increments request count" do
      Time.now.to_f
      allow(memcached).to receive(:get).with(cache_key).and_return([])
      allow(memcached).to receive(:set) do |_key, timestamps|
        allow(memcached).to receive(:get).with(cache_key).and_return(timestamps)
      end

      expect do
        store.record_request(key, period)
      end.to change { store.count_requests(key, period) }.by(1)
    end

    it "stores timestamps as array" do
      allow(memcached).to receive(:get).with(cache_key).and_return([])
      expect(memcached).to receive(:set).with(cache_key, kind_of(Array), period)
      store.record_request(key, period)
    end
  end

  context "when memcached is not configured" do
    before do
      allow(RailsRateLimit.configuration).to receive(:memcached_connection).and_return(nil)
    end

    it "raises an error" do
      expect { described_class.new }.to raise_error("Memcached connection not configured")
    end
  end
end
