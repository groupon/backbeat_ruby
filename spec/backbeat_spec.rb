require "spec_helper"
require "backbeat"

describe Backbeat do

  it "allows the default context to be configured" do
    Backbeat.configure do |config|
      config.context = Backbeat::Context::Remote
    end

    expect(Backbeat.config.context).to eq(Backbeat::Context::Remote)
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

  it "defaults to the backbeat api in a remote context" do
    Backbeat.configure do |config|
      config.context = Backbeat::Context::Remote
    end

    expect(Backbeat.api).to be_a(Backbeat::Api)
  end

  it "defaults to an empty hash in a local context" do
    Backbeat.configure do |config|
      config.context = Backbeat::Context::Local
    end

    expect(Backbeat.api).to eq({})
  end

  it "throws an error if the default context is not configured" do
    Backbeat.configure { |_| }

    expect { Backbeat.context }.to raise_error Backbeat::ContextNotConfiguredError

    Backbeat.configure do |config|
      config.context = Backbeat::Context::Local
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

