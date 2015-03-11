require "spec_helper"
require "backbeat/contextable"
require "backbeat/action"

describe Backbeat::Action do

  class MyContextible
    include Backbeat::Contextable

    def boom
      raise
    end

    def perform(a, b, c)
      a + b + c
    end
  end

  let(:context) { Backbeat::Context::Local.new({ event_name: "Maths" }) }

  let(:action) { described_class.new(MyContextible.new, :perform, [1, 2, 3]) }

  it "calls the method on the contextible object with the arguments" do
    expect(action.run(context)).to eq(6)
  end

  it "sends a processing message to the context" do
    action.run(context)
    event = context.event_history.last

    expect(event[:name]).to eq("Maths")
    expect(event[:statuses].first).to eq(:processing)
  end

  it "sends a complete message to the context" do
    action.run(context)
    event = context.event_history.last

    expect(event[:name]).to eq("Maths")
    expect(event[:statuses].last).to eq(:completed)
  end

  it "sends an error message to the context on error" do
    action = described_class.new(MyContextible, :boom, [])

    expect { action.run(context) }.to raise_error

    event = context.event_history.last

    expect(event[:name]).to eq("Maths")
    expect(event[:statuses].last).to eq(:errored)
  end
end
