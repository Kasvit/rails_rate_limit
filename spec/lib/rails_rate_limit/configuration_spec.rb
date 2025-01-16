# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Configuration do
  subject { described_class.new }

  describe "#initialize" do
    it "sets default store to :redis" do
      expect(subject.default_store).to eq(:redis)
    end

    it "initializes redis_connection as nil" do
      expect(subject.redis_connection).to be_nil
    end

    it "initializes memcached_connection as nil" do
      expect(subject.memcached_connection).to be_nil
    end

    it "initializes logger as nil" do
      expect(subject.logger).to be_nil
    end

    it "sets a default response" do
      expect(subject.default_response).to be_a(Proc)
    end
  end

  describe "#default_response=" do
    it "raises an error if handler is not a Proc" do
      expect do
        subject.default_response = "not a proc"
      end.to raise_error(ArgumentError, "default_response must be a Proc")
    end

    it "sets the default_response if handler is a Proc" do
      proc = -> { "custom response" }
      subject.default_response = proc
      expect(subject.default_response).to eq(proc)
    end
  end
end
