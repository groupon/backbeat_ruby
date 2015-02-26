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

  let(:action) { Backbeat::Action::Activity.new(name: "Fake Action") }

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
        Backbeat::Packer.pack_action(action, :blocking, now)
      )
    end

    it "creates a new workflow if one is not found" do
      new_data = workflow_data.merge(subject: "New Subject")
      registry = described_class.new(:blocking, now, new_data, api)

      registry.run(action)

      expect(api.find_workflow_by_id(6)[:signals]["Fake Action"]).to eq(
        Backbeat::Packer.pack_action(action, :blocking, now)
      )
    end

    it "registers a child node if there is an event_id in the workflow data" do
      registry = described_class.new(:non_blocking, now, { event_id: 10 }, api)

      registry.run(action)

      expect(api.find_event_by_id(10)[:child_events].first).to eq(
        Backbeat::Packer.pack_action(action, :non_blocking, now)
      )
    end
  end
end
