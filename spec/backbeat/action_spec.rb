require "spec_helper"
require "backbeat/workflowable"
require "backbeat/action"

describe Backbeat::Action do

  class MyWorkflowable
    include Backbeat::Workflowable

    def boom
      raise
    end

    def perform(a, b, c)
      a + b + c
    end
  end

  let(:workflow) { Backbeat::Workflow::Local.new({ event_name: "Maths" }) }

  let(:action) { described_class.new(MyWorkflowable.new, :perform, [1, 2, 3]) }

  it "calls the method on the workflowable object with the arguments" do
    expect(action.run(workflow)).to eq(6)
  end

  it "sends a processing message to the workflow" do
    action.run(workflow)
    event = workflow.event_history.last

    expect(event[:name]).to eq("Maths")
    expect(event[:statuses].first).to eq(:processing)
  end

  it "sends a complete message to the workflow" do
    action.run(workflow)
    event = workflow.event_history.last

    expect(event[:name]).to eq("Maths")
    expect(event[:statuses].last).to eq(:completed)
  end

  it "sends an error message to the workflow on error" do
    action = described_class.new(MyWorkflowable, :boom, [])

    expect { action.run(workflow) }.to raise_error

    event = workflow.event_history.last

    expect(event[:name]).to eq("Maths")
    expect(event[:statuses].last).to eq(:errored)
  end
end
