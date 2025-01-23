# frozen_string_literal: true

require "rails/generators"

module RailsRateLimit
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      desc "Creates a RailsRateLimit initializer file at config/initializers"

      def copy_initializer
        template "initializer.rb", "config/initializers/rails_rate_limit.rb"
      end
    end
  end
end
