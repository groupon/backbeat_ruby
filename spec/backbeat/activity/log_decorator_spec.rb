require "spec_helper"
require "backbeat/activity/log_decorator"
require "support/mock_logger"

describe Backbeat::Activity::LogDecorator do
  class MockActivity
    def initialize(&activity)
      @run = activity
    end

    def run(workflow)
      @run.call(workflow)
    end
  end

  let(:logger) { Backbeat::MockLogger.new }

  it "logs around running the activity" do
    activity = MockActivity.new { :done }
    decorator = described_class.new(activity, logger)

    decorator.run(:workflow)

    expect(logger.msgs[:info].count).to eq(2)
    expect(logger.msgs[:info].first[:name]).to eq(:activity_started)
    expect(logger.msgs[:info].last[:name]).to eq(:activity_complete)
  end

  it "logs errors in the activity" do
    activity = MockActivity.new { raise "Error" }
    decorator = described_class.new(activity, logger)

    expect { decorator.run(:workflow) }.to raise_error RuntimeError, "Error"

    expect(logger.msgs[:info].count).to eq(1)
    expect(logger.msgs[:info].first[:name]).to eq(:activity_started)
    expect(logger.msgs[:error].count).to eq(1)
    expect(logger.msgs[:error].last[:name]).to eq(:activity_errored)
  end
end
