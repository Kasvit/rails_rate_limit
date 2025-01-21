# frozen_string_literal: true

class ReportGenerator
  include RailsRateLimit::Klass

  attr_reader :organization_id

  def initialize(organization_id)
    @organization_id = organization_id
  end

  def generate
    "Report for organization #{organization_id} generated at #{Time.now}"
  end

  set_rate_limit :generate,
                 limit: 2,
                 period: 10.seconds,
                 by: -> { "report:org:#{organization_id}" }

  def self.safe_generate(organization_id)
    new(organization_id).safe_generate
  end

  def safe_generate
    generate
  rescue RailsRateLimit::RateLimitExceeded => e
    Rails.logger.warn("Rate limit exceeded for organization #{organization_id}: #{e.message}")
    false
  end
end
