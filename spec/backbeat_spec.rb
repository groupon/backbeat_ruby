require "spec_helper"
require "backbeat"

describe Backbeat do

  it "allows the default context to be configured" do
    Backbeat.configure do |config|
      config.context = :remote
    end

    expect(Backbeat.config.context).to eq(:remote)
  end

  it "allows the backbeat host to be configured" do
    Backbeat.configure do |config|
      config.host = "http://backbeat.com"
    end

    expect(Backbeat.config.host).to eq("http://backbeat.com")
  end

  it "allows the backbeat client id to be configured" do
    Backbeat.configure do |config|
      config.client_id = "123"
    end

    expect(Backbeat.config.client_id).to eq("123")
  end

  it "allows the backbeat api to be configured" do
    Backbeat.configure do |config|
      config.api = { events: [1, 2] }
    end

    expect(Backbeat.api).to eq({ events: [1, 2] })
  end

  require "logger"

  it "allows the logger to be configured" do
    logger = Logger.new("/dev/null")
    Backbeat.configure do |config|
      config.logger = logger
      config.logger.level = Logger::WARN
    end

    expect(Backbeat.config.logger).to eq(logger)
    expect(logger.level).to eq(Logger::WARN)
  end

  it "returns the correct workflow type for a remote context" do
    Backbeat.configure do |config|
      config.context = :remote
    end

    expect(Backbeat.workflow_type).to eq(Backbeat::Workflow::Remote)
  end

  it "returns the correct workflow type for a local context" do
    Backbeat.configure do |config|
      config.context = :local
    end

    expect(Backbeat.workflow_type).to eq(Backbeat::Workflow::Local)
  end

  it "defaults to the backbeat api in a remote context" do
    Backbeat.configure do |config|
      config.context = :remote
    end

    expect(Backbeat.api).to be_a(Backbeat::Api)
  end

  it "defaults to an empty hash in a local context" do
    Backbeat.configure do |config|
      config.context = :local
    end

    expect(Backbeat.api).to eq({})
  end

  it "raises an error if the context is unknown" do
    Backbeat.configure do |config|
      config.context = :foo
    end

    expect { Backbeat.api }.to raise_error Backbeat::ConfigurationError
  end

  it "raises an error if the default context is not configured" do
    Backbeat.configure { |_| }

    expect { Backbeat.context }.to raise_error Backbeat::ConfigurationError

    Backbeat.configure do |config|
      config.context = :local
    end

    expect { Backbeat.context }.to_not raise_error
  end

  it "yields a local workflow to use" do
    Backbeat.local do |workflow|
      workflow.complete_workflow!

      expect(workflow.event_history.last[:name]).to eq(:workflow_complete)
    end
  end
end

