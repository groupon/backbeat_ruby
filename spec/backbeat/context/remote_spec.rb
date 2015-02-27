require "spec_helper"
require "support/memory_api"
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

    expect(api.find_event_by_id(6)[:status]).to eq(:complete)
  end

  it "marks an event as errored" do
    context = described_class.new({ event_id: 6 }, api)
    context.errored

    expect(api.find_event_by_id(6)[:status]).to eq(:errored)
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

  context "run_activity" do
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
      name: "Workflow"
    }}

    let(:action) { Backbeat::Actors::Activity.new(name: "Fake Action") }
    let(:now) { Time.now }

    it "signals the workflow if there is no event id in the workflow data" do
      context = described_class.new(workflow_data, api)

      context.run_activity(action, :blocking, now)

      expect(api.find_workflow_by_id(5)[:signals]["Fake Action"]).to eq(
        Backbeat::Packer.pack_action(action, :blocking, now)
      )
    end

    it "creates a new workflow if one is not found" do
      new_data = workflow_data.merge(subject: "New Subject")
      context = described_class.new(new_data, api)

      context.run_activity(action, :blocking, now)

      expect(api.find_workflow_by_id(6)[:signals]["Fake Action"]).to eq(
        Backbeat::Packer.pack_action(action, :blocking, now)
      )
    end

    it "registers a child node if there is an event_id in the workflow data" do
      context = described_class.new({ event_id: 10 }, api)

      context.run_activity(action, :non_blocking, now)

      expect(api.find_event_by_id(10)[:child_events].first).to eq(
        Backbeat::Packer.pack_action(action, :non_blocking, now)
      )
    end
  end
end
