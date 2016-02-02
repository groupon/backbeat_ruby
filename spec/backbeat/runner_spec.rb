require "spec_helper"
require "backbeat/runner"
require "support/mock_logger"

describe Backbeat::Runner do
  class MockActivity
    def initialize(&activity)
      @block = activity
    end

    def object
      Object.new
    end

    def done?
      @done
    end

    def done
      @done = true
    end

    def run
      @block.call
      done
    end

    def params
      [1]
    end

    def name
      "Activity"
    end
  end

  let(:logger) { Backbeat::MockLogger.new }
  let(:config) do
    config = Backbeat::Config.new
    config.logger = logger
    config
  end
  let(:workflow) { Object.new }

  it "runs the activity" do
    activity = MockActivity.new { :done }
    runner = described_class.new(config)

    runner.call(activity, workflow)

    expect(activity.done?).to eq(true)
  end

  it "logs around running the activity" do
    activity = MockActivity.new { :done }
    runner = described_class.new(config)

    runner.call(activity, workflow)

    expect(logger.msgs[:info].count).to eq(2)
    expect(logger.msgs[:info].first[:name]).to eq(:activity_started)
    expect(logger.msgs[:info].last[:name]).to eq(:activity_complete)
  end

  it "logs errors in the activity" do
    activity = MockActivity.new { raise "Error" }
    runner = described_class.new(config)

    runner.call(activity, workflow)

    expect(logger.msgs[:info].count).to eq(1)
    expect(logger.msgs[:info].first[:name]).to eq(:activity_started)
    expect(logger.msgs[:error].count).to eq(1)
    expect(logger.msgs[:error].last[:name]).to eq(:activity_errored)
  end

  let(:new_runner) {
    Class.new do
      def self.called
        @called = true
      end

      def self.called?
        @called
      end

      def initialize(chain, config)
        @chain = chain
      end

      def call(activity, workflow)
        self.class.called
        @chain.call(activity, workflow)
      end
    end
  }

  it "can be extended with other runners" do
    Backbeat::Runner.chain.add(new_runner)
    activity = MockActivity.new { :done }
    runner = described_class.new(config)

    runner.call(activity, workflow)
    Backbeat::Runner.chain.remove(new_runner)

    expect(new_runner.called?).to eq(true)
  end
end
