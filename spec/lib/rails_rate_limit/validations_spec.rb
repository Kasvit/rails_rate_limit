# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Validations do
  describe ".validate_options!" do
    it "raises an error for invalid limit" do
      expect do
        described_class.validate_options!(limit: -1, period: 3600)
      end.to raise_error(ArgumentError, "limit must be positive")
    end

    it "raises an error for invalid period" do
      expect do
        described_class.validate_options!(limit: 100, period: -1)
      end.to raise_error(ArgumentError, "period must be a positive integer (seconds)")
    end

    it "raises an error for unsupported store" do
      expect do
        described_class.validate_options!(limit: 100, period: 3600, store: :invalid)
      end.to raise_error(ArgumentError, "unsupported store: invalid")
    end

    it "validates on_exceeded as Proc" do
      expect do
        described_class.validate_options!(
          limit: 100,
          period: 3600,
          on_exceeded: "not a proc"
        )
      end.to raise_error(ArgumentError, "on_exceeded must be a Proc")
    end

    it "accepts valid options" do
      expect do
        described_class.validate_options!(
          limit: 100,
          period: 3600,
          by: -> { "key" },
          on_exceeded: -> { "exceeded" },
          store: :redis
        )
      end.not_to raise_error
    end
  end
end
