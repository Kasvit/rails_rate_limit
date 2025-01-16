# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit do
  describe "Errors" do
    it "raises RateLimitExceeded error" do
      expect { raise RailsRateLimit::RateLimitExceeded }.to raise_error(RailsRateLimit::RateLimitExceeded)
    end

    it "raises StoreError error" do
      expect { raise RailsRateLimit::StoreError }.to raise_error(RailsRateLimit::StoreError)
    end
  end
end
