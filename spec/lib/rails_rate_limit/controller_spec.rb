# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Controller do
  let(:controller_class) do
    Class.new do
      def self.before_action(*args); end
      def self.skip_before_action(*args); end
      include RailsRateLimit::Controller

      def self.name
        "TestController"
      end

      def request
        OpenStruct.new(remote_ip: "127.0.0.1")
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

    it "accumulates rate limits" do
      controller_class.set_rate_limit(limit: 5, period: 60)
      controller_class.set_rate_limit(limit: 10, period: 120)
      expect(controller_class.rate_limits.length).to eq(2)
    end

    it "inherits rate limits from parent class" do
      controller_class.set_rate_limit(limit: 5, period: 60)
      child_class = Class.new(controller_class) do
        def self.name
          "ChildController"
        end
      end
      child_class.set_rate_limit(limit: 10, period: 120)

      expect(child_class.rate_limits.length).to eq(2)
      expect(controller_class.rate_limits.length).to eq(1)
    end

    it "creates unique callback names for each rate limit" do
      first_callback = nil
      second_callback = nil

      allow(controller_class).to receive(:before_action) do |callback_name|
        first_callback = callback_name if first_callback.nil?
        second_callback = callback_name if first_callback && callback_name != first_callback
      end

      controller_class.set_rate_limit(limit: 5, period: 60)
      controller_class.set_rate_limit(limit: 10, period: 120)

      expect(first_callback).not_to eq(second_callback)
    end

    it "allows custom callback names through :as option" do
      callback_name = nil
      allow(controller_class).to receive(:before_action) do |name|
        callback_name = name
      end

      controller_class.set_rate_limit(limit: 5, period: 60, as: :custom_rate_limit)
      expect(callback_name).to eq(:custom_rate_limit)
    end

    it "supports skipping rate limits through skip_before_action" do
      callback_name = nil
      allow(controller_class).to receive(:before_action) do |name|
        callback_name = name
      end

      controller_class.set_rate_limit(limit: 5, period: 60, as: :custom_rate_limit)
      expect(controller_class).to respond_to(:skip_before_action)
      expect(callback_name).to eq(:custom_rate_limit)
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
