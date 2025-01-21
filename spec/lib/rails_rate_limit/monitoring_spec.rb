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

    context "when using default keys" do
      it "logs message with default class key format" do
        class TestClass
          def id
            123
          end
        end

        test_instance = TestClass.new
        key = "#{test_instance.class.name}#test_method:id=123"

        expect(logger).to receive(:warn).with(
          "Rate limit exceeded for #{key}. Limit: 10 requests per 300 seconds"
        )
        monitoring.log_exceeded(key: key, limit: 10, period: 300)
      end

      it "logs message with object_id when id is not available" do
        class TestClassWithoutId; end
        test_instance = TestClassWithoutId.new
        key = "#{test_instance.class.name}#test_method:object_id=#{test_instance.object_id}"

        expect(logger).to receive(:warn).with(
          "Rate limit exceeded for #{key}. Limit: 15 requests per 120 seconds"
        )
        monitoring.log_exceeded(key: key, limit: 15, period: 120)
      end

      it "logs message with default controller key format" do
        key = "HomeController:127.0.0.1"

        expect(logger).to receive(:warn).with(
          "Rate limit exceeded for #{key}. Limit: 100 requests per 3600 seconds"
        )
        monitoring.log_exceeded(key: key, limit: 100, period: 3600)
      end
    end

    context "when using custom keys via by option" do
      it "logs message with custom user-based key" do
        key = "user:456"

        expect(logger).to receive(:warn).with(
          "Rate limit exceeded for #{key}. Limit: 50 requests per 1800 seconds"
        )
        monitoring.log_exceeded(key: key, limit: 50, period: 1800)
      end

      it "logs message with custom organization-based key" do
        key = "organization:789:api_calls"

        expect(logger).to receive(:warn).with(
          "Rate limit exceeded for #{key}. Limit: 1000 requests per 86400 seconds"
        )
        monitoring.log_exceeded(key: key, limit: 1000, period: 86_400)
      end

      it "logs message with custom composite key" do
        key = "api:v1:user:123:endpoint:reports"

        expect(logger).to receive(:warn).with(
          "Rate limit exceeded for #{key}. Limit: 25 requests per 600 seconds"
        )
        monitoring.log_exceeded(key: key, limit: 25, period: 600)
      end
    end
  end
end
