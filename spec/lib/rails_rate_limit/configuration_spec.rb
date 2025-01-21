# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Configuration do
  subject { described_class.new }

  describe "#initialize" do
    it "sets default store to :memory" do
      expect(subject.default_store).to eq(:memory)
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

    it "sets default on_controller_exceeded handler" do
      expect(subject.handle_controller_exceeded).to be_a(Proc)
    end

    it "sets default on_method_exceeded handler" do
      expect(subject.handle_klass_exceeded).to be_a(Proc)
    end
  end

  describe "#handle_controller_exceeded=" do
    it "raises an error if handler is not a Proc" do
      expect do
        subject.handle_controller_exceeded = "not a proc"
      end.to raise_error(ArgumentError, "handle_controller_exceeded must be a Proc")
    end

    it "sets the handle_controller_exceeded if handler is a Proc" do
      proc = -> { "custom response" }
      subject.handle_controller_exceeded = proc
      expect(subject.handle_controller_exceeded).to eq(proc)
    end
  end

  describe "#handle_klass_exceeded=" do
    it "raises an error if handler is not a Proc" do
      expect do
        subject.handle_klass_exceeded = "not a proc"
      end.to raise_error(ArgumentError, "handle_klass_exceeded must be a Proc")
    end

    it "sets the handle_klass_exceeded if handler is a Proc" do
      proc = -> { "custom response" }
      subject.handle_klass_exceeded = proc
      expect(subject.handle_klass_exceeded).to eq(proc)
    end
  end
end
