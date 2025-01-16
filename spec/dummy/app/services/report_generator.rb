# frozen_string_literal: true

class ReportGenerator
  include RailsRateLimit::Klass

  attr_reader :report_type

  def initialize(report_type)
    @report_type = report_type
  end

  def generate
    "Generated #{report_type} report at #{Time.now}"
  end

  def on_exceeded
    puts "Rate limit exceeded for reports"
    nil
  end

  set_rate_limit :generate,
                 limit: 2,
                 period: 1.minute,
                 by: -> { "report:#{report_type}" },
                 on_exceeded: -> { on_exceeded }
end
