require "spec_helper"
require "backbeat/contextable"
require "backbeat/context/local"
require "backbeat/action/activity"

describe Backbeat::Action::Activity do

  class MyActivity
    extend Backbeat::Contextable

    def self.boom
      raise
    end

    def self.perform(a, b, c)
      a + b + c
    end
  end

  it "returns a hash representation of itself" do
    action = described_class.build("Blue", MyActivity, :perform, [1, 2, 3])

    expect(action.to_hash).to eq({
      type: "Activity",
      name: "Blue",
      class: MyActivity,
      method: :perform,
      args: [1, 2, 3]
    })
  end

  context "run" do
    let(:action_hash) { described_class.build("Blue", MyActivity, :perform, [1, 2, 3]).to_hash }
    let(:action) { described_class.new(action_hash) }

    let(:context) { Backbeat::Context::Local.new({ event_name: "Blue" }) }

    it "calls the method on the class with the arguments" do
      expect(action.run(context)).to eq(6)
    end

    it "sends a processing message to the context" do
      action.run(context)

      expect(context.state[:events]["Blue"][:statuses].first).to eq(:processing)
    end

    it "sends a complete message to the context" do
      action.run(context)

      expect(context.state[:events]["Blue"][:statuses].last).to eq(:complete)
    end

    it "sends an error message to the context on error" do
      action = described_class.build("Blue", MyActivity, :boom, [])

      expect { action.run(context) }.to raise_error

      expect(context.state[:events]["Blue"][:statuses].last).to eq(:errored)
    end
  end
end
