require "spec_helper"
require "support/memory_api"
require "backbeat/packer"
require "backbeat/context/remote/registry"

describe Backbeat::Context::Remote::Registry do
  let(:api) {
    MemoryApi.new(
      events: {
        10 => { child_events: [] },
        11 => { child_events: [] }
      },
      workflows: {
        5 => { signals: {}, subject: "A Subject" }
      }
    )
  }

  class MockAction
    def name
      "Fake Action"
    end

    def to_hash
      { name: name }
    end
  end

  let(:action) { MockAction.new }

  let(:now) { Time.now }

  let(:workflow_data) {{
    subject: "A Subject",
    decider: "Decider",
    name: "Workflow"
  }}

  context "run" do
    it "signals the workflow if there is no event id in the workflow data" do
      registry = described_class.new(:blocking, now, workflow_data, api)

      registry.run(action)

      expect(api.find_workflow_by_id(5)[:signals]["Fake Action"]).to eq(
        action.to_hash.merge(
          name: action.name,
          mode: :blocking,
          fires_at: now,
          client_data: {
            action: action.to_hash
          }
        )
      )
    end

    it "registers a child node if there is an event_id in the workflow data" do
      registry = described_class.new(:non_blocking, now, { event_id: 10 }, api)

      registry.run(action)

      expect(api.find_event_by_id(10)[:child_events].first).to eq(
        action.to_hash.merge(
          name: action.name,
          mode: :non_blocking,
          fires_at: now,
          client_data: {
            action: action.to_hash
          }
        )
      )
    end
  end
end
