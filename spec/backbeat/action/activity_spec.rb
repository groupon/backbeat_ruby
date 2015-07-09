require "spec_helper"
require "backbeat/workflowable"
require "backbeat/workflow/local"
require "backbeat/action/activity"

describe Backbeat::Action::Activity do

  class MyActivity
    include Backbeat::Workflowable

    def boom
      raise
    end

    def perform(a, b, c)
      a + b + c
    end
  end

  it "returns a hash representation of itself" do
    action = described_class.build("Blue", MyActivity, :perform, [1, 2, 3])

    expect(action.to_hash).to eq({
      type: "Backbeat::Action::Activity",
      name: "Blue",
      class: "MyActivity",
      method: :perform,
      args: [1, 2, 3]
    })
  end

  context "#run" do
    let(:action_hash) { described_class.build("Blue", MyActivity, :perform, [1, 2, 3]).to_hash }
    let(:action) { described_class.new(action_hash) }

    let(:workflow) { Backbeat::Workflow::Local.new({ event_name: "Blue" }) }

    it "calls the method on the class with the arguments" do
      expect(action.run(workflow)).to eq(6)
    end

    it "sends a processing message to the workflow" do
      action.run(workflow)
      event = workflow.event_history.last

      expect(event[:name]).to eq("Blue")
      expect(event[:statuses].first).to eq(:processing)
    end

    it "sends a complete message to the workflow" do
      action.run(workflow)
      event = workflow.event_history.last

      expect(event[:name]).to eq("Blue")
      expect(event[:statuses].last).to eq(:completed)
    end

    it "sends an error message to the workflow on error" do
      action = described_class.build("Blue", MyActivity, :boom, [])

      expect { action.run(workflow) }.to raise_error

      event = workflow.event_history.last

      expect(event[:name]).to eq("Blue")
      expect(event[:statuses].last).to eq(:errored)
    end
  end
end
