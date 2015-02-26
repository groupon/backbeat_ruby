require "spec_helper"
require "backbeat/contextable"
require "backbeat/action"

describe Backbeat::Action do

  class MyContextible
    extend Backbeat::Contextable

    def self.boom
      raise
    end

    def self.perform(a, b, c)
      a + b + c
    end
  end

  let(:context) { Backbeat::Context::Local.new({ event_name: "Maths" }) }

  let(:action) { described_class.new(MyContextible, :perform, [1, 2, 3]) }

  it "calls the method on the contextible object with the arguments" do
    expect(action.run(context)).to eq(6)
  end

  it "sends a processing message to the context" do
    action.run(context)

    expect(context.state[:events]["Maths"][:statuses].first).to eq(:processing)
  end

  it "sends a complete message to the context" do
    action.run(context)

    expect(context.state[:events]["Maths"][:statuses].last).to eq(:complete)
  end

  it "sends an error message to the context on error" do
    action = described_class.new("Blue", MyActivity, [:boom])

    action.run(context)

    expect(context.state[:events]["Maths"][:statuses].last).to eq(:errored)
  end
end
