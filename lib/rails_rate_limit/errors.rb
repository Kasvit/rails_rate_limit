# frozen_string_literal: true

module RailsRateLimit
  class RateLimitExceeded < StandardError; end
  class StoreError < StandardError; end
end
