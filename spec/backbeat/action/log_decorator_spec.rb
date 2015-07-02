require "spec_helper"
require "backbeat/action/log_decorator"
require "support/mock_logger"

describe Backbeat::Action::LogDecorator do
  class MockAction
    def initialize(&action)
      @run = action
    end

    def run(workflow)
      @run.call(workflow)
    end
  end

  class MockLogger
    def info(msg)
      msgs[:info] << msg
    end

    def error(msg)
      msgs[:error] << msg
    end

    def msgs
      @msgs ||= Hash.new { |h, k| h[k] = [] }
    end
  end

  let(:logger) { Backbeat::MockLogger.new }

  it "logs around running the action" do
    action = MockAction.new { :done }
    decorator = described_class.new(action, logger)

    decorator.run(:workflow)

    expect(logger.msgs[:info].count).to eq(2)
    expect(logger.msgs[:info].first[:name]).to eq(:action_started)
    expect(logger.msgs[:info].last[:name]).to eq(:action_complete)
  end

  it "logs errors in the action" do
    action = MockAction.new { raise "Error" }
    decorator = described_class.new(action, logger)

    expect{ decorator.run(:workflow) }.to raise_error

    expect(logger.msgs[:info].count).to eq(1)
    expect(logger.msgs[:info].first[:name]).to eq(:action_started)
    expect(logger.msgs[:error].count).to eq(1)
    expect(logger.msgs[:error].last[:name]).to eq(:action_errored)
  end
end
