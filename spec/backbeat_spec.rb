require "spec_helper"
require "backbeat"

describe Backbeat do

  it "allows the default context to be configured" do
    Backbeat.configure do |config|
      config.context = :some_context
    end

    expect(Backbeat.config.context).to eq(:some_context)
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

  it "throws an error if the default context is not configured" do
    Backbeat.configure do |config|
      config.context = nil
    end

    expect { Backbeat.context }.to raise_error Backbeat::ContextNotConfiguredError

    Backbeat.configure do |config|
      config.context = :some_context
    end

    expect { Backbeat.context }.to_not raise_error
  end

  it "yields a local context to use" do
    Backbeat.local do |context|
      context.complete_workflow!

      expect(context.state[:workflow_complete]).to eq(true)
    end
  end
end

