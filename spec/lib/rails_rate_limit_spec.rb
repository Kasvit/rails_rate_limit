# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit do
  describe ".configure" do
    it "yields the configuration" do
      expect { |b| RailsRateLimit.configure(&b) }.to yield_with_args(RailsRateLimit.configuration)
    end
  end

  describe ".configuration" do
    it "returns a configuration instance" do
      expect(RailsRateLimit.configuration).to be_a(RailsRateLimit::Configuration)
    end
  end
end
