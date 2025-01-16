# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::RateLimiter do
  let(:context) { double("Context", request: double(remote_ip: "127.0.0.1"), response: double(headers: {})) }
  let(:store_name) { :redis }
  let(:rate_limiter) do
    described_class.new(
      context: context,
      by: nil,
      limit: 5,
      period: 60,
      store: store_name
    )
  end

  before do
    # Очищаємо Redis перед кожним тестом
    Redis.new.flushdb
  end

  describe "#perform!" do
    it "does not raise an error when within limit" do
      expect { rate_limiter.perform! }.not_to raise_error
    end

    it "raises RateLimitExceeded when limit is exceeded" do
      5.times { rate_limiter.perform! }
      expect { rate_limiter.perform! }.to raise_error(RailsRateLimit::RateLimitExceeded)
    end
  end
end
