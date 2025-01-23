# frozen_string_literal: true

require "rails/generators"
require_relative "../../../../lib/generators/rails_rate_limit/install/install_generator"

RSpec.describe RailsRateLimit::Generators::InstallGenerator do
  let(:destination_root) { File.expand_path("../../../tmp", __dir__) }

  before(:each) do
    FileUtils.rm_rf(destination_root)
    FileUtils.mkdir_p(destination_root)
    FileUtils.cd(destination_root)
  end

  after(:each) do
    FileUtils.rm_rf(destination_root)
  end

  it "creates initializer file" do
    described_class.start([], destination_root: destination_root)

    expect(File).to exist(File.join(destination_root, "config/initializers/rails_rate_limit.rb"))
  end

  it "initializer file contains correct content" do
    described_class.start([], destination_root: destination_root)

    content = File.read(File.join(destination_root, "config/initializers/rails_rate_limit.rb"))
    expect(content).to include("RailsRateLimit.configure do |config|")
  end
end
