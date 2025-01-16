# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsRateLimit::Klass do
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

  before do
    RailsRateLimit.configure do |config|
      config.default_store = :memory
      config.default_on_method_exceeded = -> { nil }
    end
    RailsRateLimit::Stores::Memory.instance.clear
  end

  describe ".set_rate_limit" do
    it "allows calls within the limit" do
      expect(instance.test_method).to eq("success")
      expect(instance.test_method).to eq("success")
    end

    it "returns nil when limit is exceeded" do
      2.times { instance.test_method }
      expect(instance.test_method).to be_nil
    end

    it "tracks limits separately for different instances" do
      another_instance = test_class.new(2)

      2.times { instance.test_method }
      expect(instance.test_method).to be_nil

      expect(another_instance.test_method).to eq("success")
    end

    context "with custom identifier" do
      let(:test_class_with_custom_key) do
        Class.new do
          include RailsRateLimit::Klass

          def test_method
            "success"
          end

          set_rate_limit :test_method,
                         limit: 2,
                         period: 3600,
                         by: -> { "custom_key" }
        end
      end

      it "uses custom key for rate limiting" do
        instance1 = test_class_with_custom_key.new
        instance2 = test_class_with_custom_key.new

        2.times { instance1.test_method }

        expect(instance2.test_method).to be_nil
      end
    end

    context "with dynamic limit" do
      let(:test_class_with_dynamic_limit) do
        Class.new do
          include RailsRateLimit::Klass

          attr_reader :limit

          def initialize(limit)
            @limit = limit
          end

          def test_method
            "success"
          end

          set_rate_limit :test_method,
                         limit: -> { limit },
                         period: 3600
        end
      end

      it "respects dynamic limit" do
        instance = test_class_with_dynamic_limit.new(3)

        3.times { instance.test_method }

        expect(instance.test_method).to be_nil
      end
    end

    context "with custom on_exceeded handler" do
      let(:test_class_with_handler) do
        Class.new do
          include RailsRateLimit::Klass

          attr_reader :handler_called

          def initialize
            @handler_called = false
          end

          def test_method
            "success"
          end

          set_rate_limit :test_method,
                         limit: 2,
                         period: 3600,
                         on_exceeded: lambda {
                           @handler_called = true
                           "rate limit exceeded"
                         }
        end
      end

      it "executes custom handler and returns nil when limit is exceeded" do
        instance = test_class_with_handler.new

        2.times { instance.test_method }

        result = instance.test_method
        expect(result).to be_nil
        expect(instance.handler_called).to be true
      end
    end

    context "with default on_method_exceeded handler" do
      let(:test_class_with_default_handler) do
        Class.new do
          include RailsRateLimit::Klass

          def test_method
            "success"
          end

          set_rate_limit :test_method,
                         limit: 2,
                         period: 3600
        end
      end

      it "executes default handler and returns nil when limit is exceeded" do
        handler_called = false

        RailsRateLimit.configure do |config|
          config.default_on_method_exceeded = lambda {
            handler_called = true
            "default exceeded"
          }
        end

        instance = test_class_with_default_handler.new
        2.times { instance.test_method }

        expect(instance.test_method).to be_nil
        expect(handler_called).to be true
      end
    end
  end
end
