# frozen_string_literal: true

class Report
  include RailsRateLimit::Klass

  def generate
    "Report generated"
  end

  set_rate_limit :generate,
                 limit: 2,
                 period: 60

  def self.generate_daily_report
    "Daily report generated"
  end

  set_rate_limit :generate_daily_report,
                 limit: 2,
                 period: 60

  def self.generate_weekly_report
    "Weekly report generated"
  end

  set_rate_limit :generate_weekly_report,
                 limit: 3,
                 period: 60,
                 on_exceeded: -> { "Weekly report limit exceeded" }
end
