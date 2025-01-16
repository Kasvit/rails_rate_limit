# frozen_string_literal: true

require "rails_rate_limit/version"
require "rails_rate_limit/configuration"
require "rails_rate_limit/controller"
require "rails_rate_limit/errors"
require "rails_rate_limit/monitoring"
require "rails_rate_limit/rate_limiter"
require "rails_rate_limit/stores/base"
require "rails_rate_limit/stores/redis"
require "rails_rate_limit/stores/memory"
require "rails_rate_limit/stores/memcached"
require "rails_rate_limit/validations"

module RailsRateLimit
  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def logger
      configuration.logger
    end
  end
end
