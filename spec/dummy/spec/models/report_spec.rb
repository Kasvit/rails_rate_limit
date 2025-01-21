# frozen_string_literal: true

require "rails_helper"

RSpec.describe Report do
  before do
    RailsRateLimit.configure do |config|
      config.default_store = :memory
      config.handle_klass_exceeded = -> { nil }
    end
    RailsRateLimit::Stores::Memory.instance.clear
  end

  describe "instance methods" do
    let(:report) { described_class.new }

    it "allows generating reports within limit" do
      expect(report.generate).to eq("Report generated")
      expect(report.generate).to eq("Report generated")
    end

    it "handles rate limit exceeded" do
      2.times { report.generate }
      expect(report.generate).to be_nil
    end
  end

  describe "class methods" do
    describe ".generate_daily_report" do
      it "allows generating reports within limit" do
        expect(described_class.generate_daily_report).to eq("Daily report generated")
        expect(described_class.generate_daily_report).to eq("Daily report generated")
      end

      it "handles rate limit exceeded" do
        2.times { described_class.generate_daily_report }
        expect(described_class.generate_daily_report).to be_nil
      end
    end

    describe ".generate_weekly_report" do
      it "returns custom error message when limit exceeded" do
        3.times { described_class.generate_weekly_report }
        expect(described_class.generate_weekly_report).to eq("Weekly report limit exceeded")
      end
    end
  end
end
