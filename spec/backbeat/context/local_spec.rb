require "spec_helper"
require "backbeat/contextable"
require "backbeat/action/activity"
require "backbeat/context/local"

describe Backbeat::Context::Local do

  it "returns the workflow event history" do
    context = described_class.new({ event_name: "First Event" }, { event_history: [:one] })
    history = context.event_history

    expect(history).to eq([:one])
  end

  it "marks an event as processing" do
    context = described_class.new({ event_name: "First Event" })
    context.processing

    event = context.event_history.first
    expect(event[:name]).to eq("First Event")
    expect(event[:statuses]).to eq([:processing])
  end

  it "marks an event as complete" do
    context = described_class.new({ event_name: "First Event" })
    context.complete

    event = context.event_history.first
    expect(event[:statuses]).to eq([:complete])
  end

  it "marks an event as errored" do
    context = described_class.new({ event_name: "First Event" })
    context.errored

    event = context.event_history.first
    expect(event[:statuses]).to eq([:errored])
  end

  it "completes a workflow" do
    context = described_class.new({ event_name: "First Event" })
    context.complete_workflow!

    expect(context.event_history.last[:name]).to eq(:workflow_complete)
  end

  class TheActivity
    extend Backbeat::Contextable

    def self.do_some_addition(a, b, c)
      answer = a + b + c
      [answer, context]
    end

    def self.return_the_arg(arg)
      arg
    end
  end

  context "running activities" do
    let(:context) { described_class.new({ event_name: "First Event", workflow_id: 2 }) }
    let(:now) { Time.now }

    it "runs a workflow locally" do
      action = Backbeat::Action::Activity.build("Adding", TheActivity, :do_some_addition, [10, 11, 12])

      value, new_context = context.run_activity(action, :blocking)
      event = context.event_history.last

      expect(value).to eq(33)
      expect(event[:name]).to eq("Adding")
      expect(event[:action]).to eq(action.to_hash)
      expect(event[:statuses].last).to eq(:complete)
    end

    it "runs the workflow locally on signal_workflow" do
      action = Backbeat::Action::Activity.build("MATH", TheActivity, :do_some_addition, [3, 2, 1])

      value, new_context = context.signal_workflow(action, now)
      event = context.event_history.last

      expect(value).to eq(6)
      expect(event[:name]).to eq("MATH")
      expect(event[:action]).to eq(action.to_hash)
      expect(event[:statuses].last).to eq(:complete)
    end

    it "json parses the action arguments to ensure proper expectations during testing" do
      action = Backbeat::Action::Activity.build("Compare symbols", TheActivity, :return_the_arg, [:orange])

      value, new_context = context.run_activity(action, :blocking)

      expect(value).to eq("orange")
    end
  end
end
