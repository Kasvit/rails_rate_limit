# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Validations do
  describe ".validate_options!" do
    it "raises an error for invalid limit" do
      expect do
        RailsRateLimit::Validations.validate_options!(limit: -1,
                                                      period: 60)
      end.to raise_error(ArgumentError, "limit must be positive")
    end

    it "raises an error for invalid period" do
      expect do
        RailsRateLimit::Validations.validate_options!(limit: 5,
                                                      period: -1)
      end.to raise_error(ArgumentError, "period must be a positive integer (seconds)")
    end

    it "raises an error for unsupported store" do
      expect do
        RailsRateLimit::Validations.validate_options!(limit: 5, period: 60,
                                                      store: :unsupported)
      end.to raise_error(ArgumentError, "unsupported store: unsupported")
    end
  end
end
