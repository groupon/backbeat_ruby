require "spec_helper"
require "support/memory_api"
require "backbeat/action/activity"
require "backbeat/packer"
require "backbeat/context/remote"

describe Backbeat::Context::Remote do
  let(:api) {
    Backbeat::MemoryApi.new(
      events: {
        5 => {},
        6 => {}
      },
      workflows: {
        1 => { events: [:event_1, :event_2, :event_3] },
        2 => { complete: false }
      }
    )
  }

  it "marks an event as processing" do
    context = described_class.new({ event_id: 5 }, api)
    context.processing

    expect(api.find_event_by_id(5)[:status]).to eq(:processing)
  end

  it "marks an event as complete" do
    context = described_class.new({ event_id: 6 }, api)
    context.complete

    expect(api.find_event_by_id(6)[:status]).to eq(:completed)
  end

  it "marks an event as errored" do
    context = described_class.new({ event_id: 6 }, api)
    context.errored

    expect(api.find_event_by_id(6)[:status]).to eq(:errored)
  end

  it "marks an event and previous events as deactivated" do
    context = described_class.new({ event_id: 6 }, api)
    context.deactivated

    expect(api.find_event_by_id(5)[:status]).to eq(:deactivated)
    expect(api.find_event_by_id(6)[:status]).to eq(:deactivated)
  end

  it "returns the workflow event history" do
    context = described_class.new({ event_id: 6, workflow_id: 1 }, api)
    history = context.event_history

    expect(history).to eq([:event_1, :event_2, :event_3])
  end

  it "completes a workflow" do
    context = described_class.new({ event_id: 6, workflow_id: 2 }, api)
    context.complete_workflow!

    expect(api.find_workflow_by_id(2)[:complete]).to eq(true)
  end

  context "running activities" do
    let(:api) {
      Backbeat::MemoryApi.new(
        events: {
          10 => { child_events: [] },
          11 => { child_events: [] }
        },
        workflows: {
          5 => { signals: {}, subject: "A Subject" }
        }
      )
    }

    let(:workflow_data) {{
      subject: "A Subject",
      decider: "Decider",
      name: "Workflow",
      workflow_type: "Workflow"
    }}

    let(:action) { Backbeat::Action::Activity.new(name: "Fake Action") }
    let(:now) { Time.now }

    it "raises an error if there is not an event id when running an activity" do
      context = described_class.new(workflow_data, api)

      expect { context.run_activity(action, :blocking, now) }.to raise_error Backbeat::Context::Remote::ContextError
    end

    it "registers a child node if there is an event_id in the workflow data" do
      context = described_class.new({ event_id: 10 }, api)

      context.run_activity(action, :non_blocking, now)

      event_id = api.find_event_by_id(10)[:child_events].first
      event = api.find_event_by_id(event_id)

      expect(event).to eq(
        Backbeat::Packer.pack_action(action, :non_blocking, now).merge(id: 12)
      )
    end

    it "creates a new workflow if one is not found when signalling" do
      new_data = workflow_data.merge(subject: "New Subject")
      context = described_class.new(new_data, api)

      context.signal_workflow(action)

      expect(api.find_workflow_by_id(6)[:signals]["Fake Action"]).to eq(
        Backbeat::Packer.pack_action(action, :blocking, nil).merge(id: 12)
      )
    end

    it "signals the workflow with the action when signalling" do
      context = described_class.new(workflow_data, api)

      context.signal_workflow(action, now)

      expect(api.find_workflow_by_id(5)[:signals]["Fake Action"]).to eq(
        Backbeat::Packer.pack_action(action, :blocking, now).merge(id: 12)
      )
    end
  end
end
