require "spec_helper"
require "backbeat/workflowable"
require "backbeat/action/activity"
require "backbeat/workflow/local"

describe Backbeat::Workflow::Local do

  it "returns the workflow event history" do
    workflow = described_class.new({ event_name: "First Event" }, { event_history: [:one] })
    history = workflow.event_history

    expect(history).to eq([:one])
  end

  it "marks an event as processing" do
    workflow = described_class.new({ event_name: "First Event" })
    workflow.processing

    event = workflow.event_history.first
    expect(event[:name]).to eq("First Event")
    expect(event[:statuses]).to eq([:processing])
  end

  it "marks an event as complete" do
    workflow = described_class.new({ event_name: "First Event" })
    workflow.complete

    event = workflow.event_history.first
    expect(event[:statuses]).to eq([:completed])
  end

  it "marks an event and previous events as deactivated" do
    workflow = described_class.new(
      { event_name: "Second Event" },
      { event_history: [{ name: "First Event", statuses: [] }] }
    )
    workflow.deactivated

    workflow.event_history.each do |event|
      expect(event[:statuses]).to eq([:deactivated])
    end
  end

  it "marks an event as errored" do
    workflow = described_class.new({ event_name: "First Event" })
    workflow.errored

    event = workflow.event_history.first
    expect(event[:statuses]).to eq([:errored])
  end

  it "completes a workflow" do
    workflow = described_class.new({ event_name: "First Event" })
    workflow.complete_workflow!

    expect(workflow.event_history.last[:name]).to eq(:workflow_complete)
  end

  class TheActivity
    include Backbeat::Workflowable

    def do_some_addition(a, b, c)
      answer = a + b + c
      [answer, workflow]
    end

    def return_the_arg(arg)
      arg
    end
  end

  context "running activities" do
    let(:workflow) { described_class.new({ event_name: "First Event", workflow_id: 2 }) }
    let(:now) { Time.now }

    it "runs a workflow locally" do
      action = Backbeat::Action::Activity.build("Adding", TheActivity, :do_some_addition, [10, 11, 12])

      value, new_workflow = workflow.run_activity(action, :blocking)
      event = workflow.event_history.last

      expect(value).to eq(33)
      expect(event[:name]).to eq("Adding")
      expect(event[:action]).to eq(action.to_hash)
      expect(event[:statuses].last).to eq(:completed)
    end

    it "runs the workflow locally on signal_workflow" do
      action = Backbeat::Action::Activity.build("MATH", TheActivity, :do_some_addition, [3, 2, 1])

      value, new_workflow = workflow.signal_workflow(action, now)
      event = workflow.event_history.last

      expect(value).to eq(6)
      expect(event[:name]).to eq("MATH")
      expect(event[:action]).to eq(action.to_hash)
      expect(event[:statuses].last).to eq(:completed)
    end

    it "json parses the action arguments to ensure proper expectations during testing" do
      action = Backbeat::Action::Activity.build("Compare symbols", TheActivity, :return_the_arg, [:orange])

      value, new_workflow = workflow.run_activity(action, :blocking)

      expect(value).to eq("orange")
    end
  end
end
