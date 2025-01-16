# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Controller do
  let(:controller_class) do
    Class.new do
      def self.before_action(*args); end
      include RailsRateLimit::Controller

      def self.name
        "TestController"
      end
    end
  end

  describe ".set_rate_limit" do
    it "adds class method to the including class" do
      expect(controller_class).to respond_to(:set_rate_limit)
    end

    it "validates options" do
      expect(RailsRateLimit::Validations).to receive(:validate_options!).with(
        hash_including(limit: 5, period: 60)
      )
      controller_class.set_rate_limit(limit: 5, period: 60)
    end

    context "with invalid options" do
      it "raises error for negative limit" do
        expect do
          controller_class.set_rate_limit(limit: -1, period: 60)
        end.to raise_error(ArgumentError, "limit must be positive")
      end

      it "raises error for negative period" do
        expect do
          controller_class.set_rate_limit(limit: 5, period: -1)
        end.to raise_error(ArgumentError, "period must be a positive integer (seconds)")
      end

      it "raises error for invalid store" do
        expect do
          controller_class.set_rate_limit(limit: 5, period: 60, store: :invalid)
        end.to raise_error(ArgumentError, "unsupported store: invalid")
      end
    end
  end
end
