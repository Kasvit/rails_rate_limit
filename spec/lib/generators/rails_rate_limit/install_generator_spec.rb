# frozen_string_literal: true

require "rails/generators"
require_relative "../../../../lib/generators/rails_rate_limit/install/install_generator"

RSpec.describe RailsRateLimit::Generators::InstallGenerator do
  let(:destination_root) { File.expand_path("tmp/generators", Dir.pwd) }

  around do |example|
    FileUtils.mkdir_p(destination_root)
    Dir.chdir(destination_root) do
      example.run
    end
    FileUtils.rm_rf(destination_root)
  end

  it "creates initializer file" do
    silence_stream($stdout) { described_class.start([], destination_root: destination_root) }

    expect(File).to exist(File.join(destination_root, "config/initializers/rails_rate_limit.rb"))
  end

  it "initializer file contains correct content" do
    silence_stream($stdout) { described_class.start([], destination_root: destination_root) }

    content = File.read(File.join(destination_root, "config/initializers/rails_rate_limit.rb"))
    expect(content).to include("RailsRateLimit.configure do |config|")
  end

  private

  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(IO::NULL)
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
    old_stream.close
  end
end
