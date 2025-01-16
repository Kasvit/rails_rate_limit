# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Monitoring do
  let(:logger) { double("Logger", warn: true) }
  let(:monitoring) { described_class.new(logger: logger) }

  describe "#log_exceeded" do
    it "logs the exceeded rate limit when logger is present" do
      expect(logger).to receive(:warn).with(
        "Rate limit exceeded for test_key. Limit: 5 requests per 60 seconds"
      )
      monitoring.log_exceeded(key: "test_key", limit: 5, period: 60)
    end

    it "does not raise error when logger is nil" do
      monitoring = described_class.new(logger: nil)
      expect do
        monitoring.log_exceeded(key: "test_key", limit: 5, period: 60)
      end.not_to raise_error
    end
  end
end
