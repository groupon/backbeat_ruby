require "spec_helper"
require "support/memory_api"
require "backbeat/serializer/activity"
require "backbeat/packer"
require "backbeat/workflow/remote"

describe Backbeat::Workflow::Remote do
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

  context "#event_processing" do
    it "marks an event as processing" do
      workflow = described_class.new({ event_id: 5 }, api)
      workflow.event_processing

      expect(api.find_event_by_id(5)[:status]).to eq(:processing)
    end
  end

  context "#event_completed" do
    it "marks an event as completed" do
      workflow = described_class.new({ event_id: 6 }, api)
      workflow.event_completed

      expect(api.find_event_by_id(6)[:status]).to eq(:completed)
    end
  end

  context "#event_errored" do
    it "marks an event as errored" do
      workflow = described_class.new({ event_id: 6 }, api)
      workflow.event_errored

      expect(api.find_event_by_id(6)[:status]).to eq(:errored)
    end
  end

  context "#deactivate" do
    it "marks an event and previous events as deactivated" do
      workflow = described_class.new({ event_id: 6 }, api)
      workflow.deactivate

      expect(api.find_event_by_id(5)[:status]).to eq(:deactivated)
      expect(api.find_event_by_id(6)[:status]).to eq(:deactivated)
    end
  end

  context "#event_history" do
    it "returns the workflow event history" do
      workflow = described_class.new({ event_id: 6, workflow_id: 1 }, api)
      history = workflow.event_history

      expect(history).to eq([:event_1, :event_2, :event_3])
    end
  end

  context "#complete" do
    it "completes a workflow" do
      workflow = described_class.new({ event_id: 6, workflow_id: 2 }, api)
      workflow.complete

      expect(api.find_workflow_by_id(2)[:complete]).to eq(true)
    end
  end

  context "#complete?" do
    let(:workflow) { described_class.new({ event_id: 6, workflow_id: 2 }, api) }
    it "returns false if the workflow is not complete" do
      expect(workflow.complete?).to eq(false)
    end

    it "returns true if the workflow is complete" do
      workflow.complete

      expect(workflow.complete?).to eq(true)
    end
  end

  context "#reset_event" do
    it "resets the current node" do
      workflow = described_class.new({ event_id: 6, workflow_id: 2 }, api)

      workflow.reset_event

      expect(api.find_event_by_id(6)[:reset]).to eq(true)
    end
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

    let(:action) { Backbeat::Serializer::Activity.new(name: "Fake Action") }
    let(:now) { Time.now }

    it "raises an error if there is not an event id when running an activity" do
      workflow = described_class.new(workflow_data, api)

      expect { workflow.run_activity(action, :blocking, now) }.to raise_error Backbeat::Workflow::Remote::WorkflowError
    end

    it "registers a child node if there is an event_id in the workflow data" do
      workflow = described_class.new({ event_id: 10 }, api)

      workflow.run_activity(action, :non_blocking, now)

      event_id = api.find_event_by_id(10)[:child_events].first
      event = api.find_event_by_id(event_id)

      expect(event).to eq(
        Backbeat::Packer.pack_action(action, :non_blocking, now).merge(id: 12)
      )
    end

    it "creates a new workflow if one is not found when signalling" do
      new_data = workflow_data.merge(subject: "New Subject")
      workflow = described_class.new(new_data, api)

      workflow.signal_workflow(action)

      expect(api.find_workflow_by_id(6)[:signals]["Fake Action"]).to eq(
        Backbeat::Packer.pack_action(action, :blocking, nil).merge(id: 12)
      )
    end

    it "signals the workflow with the action when signalling" do
      workflow = described_class.new(workflow_data, api)

      workflow.signal_workflow(action, now)

      expect(api.find_workflow_by_id(5)[:signals]["Fake Action"]).to eq(
        Backbeat::Packer.pack_action(action, :blocking, now).merge(id: 12)
      )
    end
  end
end
