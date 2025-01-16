# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Stores::Base do
  describe ".resolve" do
    it "returns a Redis instance for :redis" do
      expect(RailsRateLimit::Stores::Base.resolve(:redis)).to be_a(RailsRateLimit::Stores::Redis)
    end

    it "returns a Memory instance for :memory" do
      expect(RailsRateLimit::Stores::Base.resolve(:memory)).to be_a(RailsRateLimit::Stores::Memory)
    end

    it "returns a Memcached instance for :memcached" do
      expect(RailsRateLimit::Stores::Base.resolve(:memcached)).to be_a(RailsRateLimit::Stores::Memcached)
    end

    it "raises an error for unsupported store" do
      expect do
        RailsRateLimit::Stores::Base.resolve(:unsupported)
      end.to raise_error(RailsRateLimit::StoreError, "Unsupported store: unsupported")
    end
  end
end
