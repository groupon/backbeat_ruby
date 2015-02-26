require "spec_helper"
require "support/memory_api"
require "backbeat/context/remote"

describe Backbeat::Context::Remote do
  let(:api) {
    MemoryApi.new(
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

  context "registering actions" do
    let(:context) { described_class.new({ event_id: 6, workflow_id: 2 }) }
    let(:now) { Time.now }

    it "creates a blocking action registry" do
      registry = context.blocking(now)

      expect(registry.mode).to eq(:blocking)
      expect(registry.fires_at).to eq(now)
    end

    it "creates a non blocking action registry" do
      registry = context.non_blocking(now)

      expect(registry.mode).to eq(:non_blocking)
      expect(registry.fires_at).to eq(now)
    end

    it "creates a fire and forget action registry" do
      registry = context.fire_and_forget(now)

      expect(registry.mode).to eq(:fire_and_forget)
      expect(registry.fires_at).to eq(now)
    end
  end
end
