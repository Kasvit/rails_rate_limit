# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Klass do
  before do
    RailsRateLimit.configure do |config|
      config.default_store = :memory
      config.handle_klass_exceeded = -> { nil }
    end
    RailsRateLimit::Stores::Memory.instance.clear
  end

  describe ".set_rate_limit" do
    context "with instance methods" do
      let(:test_class) do
        Class.new do
          include RailsRateLimit::Klass

          attr_reader :id

          def initialize(id)
            @id = id
          end

          def test_method
            "success"
          end

          set_rate_limit :test_method,
                         limit: 2,
                         period: 3600
        end
      end

      let(:instance) { test_class.new(1) }

      it "allows calls within the limit" do
        expect(instance.test_method).to eq("success")
        expect(instance.test_method).to eq("success")
      end

      it "handles rate limit exceeded" do
        2.times { instance.test_method }
        expect(instance.test_method).to be_nil
      end

      it "tracks limits separately for different instances" do
        another_instance = test_class.new(2)

        2.times { instance.test_method }
        expect(instance.test_method).to be_nil
        expect(another_instance.test_method).to eq("success")
      end
    end

    context "with class methods" do
      let(:test_class) do
        Class.new do
          include RailsRateLimit::Klass

          def self.name
            "TestClass"
          end

          def self.test_class_method
            "class method success"
          end

          set_rate_limit :test_class_method,
                         limit: 2,
                         period: 3600
        end
      end

      it "allows calls within the limit" do
        expect(test_class.test_class_method).to eq("class method success")
        expect(test_class.test_class_method).to eq("class method success")
      end

      it "handles rate limit exceeded" do
        2.times { test_class.test_class_method }
        expect(test_class.test_class_method).to be_nil
      end

      it "tracks limits separately for different classes" do
        another_test_class = Class.new do
          include RailsRateLimit::Klass

          def self.name
            "AnotherTestClass"
          end

          def self.test_class_method
            "another class success"
          end

          set_rate_limit :test_class_method,
                         limit: 2,
                         period: 3600
        end

        2.times { test_class.test_class_method }
        expect(test_class.test_class_method).to be_nil
        expect(another_test_class.test_class_method).to eq("another class success")
      end

      context "with custom identifier" do
        let(:test_class_with_custom_key) do
          Class.new do
            include RailsRateLimit::Klass

            def self.name
              "TestClassWithCustomKey"
            end

            def self.test_class_method
              "custom key success"
            end

            set_rate_limit :test_class_method,
                           limit: 2,
                           period: 3600,
                           by: -> { "custom_class_key" }
          end
        end

        it "uses custom key for rate limiting" do
          2.times { test_class_with_custom_key.test_class_method }
          expect(test_class_with_custom_key.test_class_method).to be_nil
        end
      end

      context "with custom handler" do
        let(:test_class_with_handler) do
          Class.new do
            include RailsRateLimit::Klass

            def self.name
              "TestClassWithHandler"
            end

            def self.test_class_method
              "handler test"
            end

            def self.handler_called
              @handler_called ||= false
            end

            class << self
              attr_writer :handler_called
            end

            set_rate_limit :test_class_method,
                           limit: 2,
                           period: 3600,
                           on_exceeded: lambda {
                             self.handler_called = true
                             "rate limit exceeded"
                           }
          end
        end

        it "executes custom handler when limit is exceeded" do
          2.times { test_class_with_handler.test_class_method }

          result = test_class_with_handler.test_class_method
          expect(result).to eq("rate limit exceeded")
          expect(test_class_with_handler.handler_called).to be true
        end
      end
    end

    context "with undefined method" do
      let(:test_class) do
        Class.new do
          include RailsRateLimit::Klass
        end
      end

      it "raises ArgumentError" do
        expect do
          test_class.set_rate_limit :undefined_method,
                                    limit: 2,
                                    period: 3600
        end.to raise_error(ArgumentError, "Method undefined_method is not defined")
      end
    end
  end
end
