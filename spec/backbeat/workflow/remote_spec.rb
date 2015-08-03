require "spec_helper"
require "support/memory_api"
require "backbeat/serializer/activity"
require "backbeat/packer"
require "backbeat/workflow/remote"

describe Backbeat::Workflow::Remote do
  let(:api) {
    Backbeat::MemoryApi.new(
      activities: {
        5 => {},
        6 => {}
      },
      workflows: {
        1 => { activities: [:activity_1, :activity_2, :activity_3] },
        2 => { complete: false }
      }
    )
  }

  context "#activity_processing" do
    it "marks an activity as processing" do
      workflow = described_class.new({ activity_id: 5 }, api)
      workflow.activity_processing

      expect(api.find_activity_by_id(5)[:status]).to eq(:processing)
    end
  end

  context "#activity_completed" do
    it "marks an activity as completed" do
      workflow = described_class.new({ activity_id: 6 }, api)
      workflow.activity_completed

      expect(api.find_activity_by_id(6)[:status]).to eq(:completed)
    end

    it "sends the result" do
      workflow = described_class.new({ activity_id: 6 }, api)
      workflow.activity_completed(:done)

      expect(api.find_activity_by_id(6)[:result]).to eq(:done)
    end
  end

  context "#activity_errored" do
    it "marks an activity as errored" do
      workflow = described_class.new({ activity_id: 6 }, api)
      workflow.activity_errored

      expect(api.find_activity_by_id(6)[:status]).to eq(:errored)
    end
  end

  context "#deactivate" do
    it "marks an activity and previous activities as deactivated" do
      workflow = described_class.new({ activity_id: 6 }, api)
      workflow.deactivate

      expect(api.find_activity_by_id(5)[:status]).to eq(:deactivated)
      expect(api.find_activity_by_id(6)[:status]).to eq(:deactivated)
    end
  end

  context "#activity_history" do
    it "returns the workflow activity history" do
      workflow = described_class.new({ activity_id: 6, workflow_id: 1 }, api)
      history = workflow.activity_history

      expect(history).to eq([:activity_1, :activity_2, :activity_3])
    end
  end

  context "#complete" do
    it "completes a workflow" do
      workflow = described_class.new({ activity_id: 6, workflow_id: 2 }, api)
      workflow.complete

      expect(api.find_workflow_by_id(2)[:complete]).to eq(true)
    end
  end

  context "#complete?" do
    let(:workflow) { described_class.new({ activity_id: 6, workflow_id: 2 }, api) }
    it "returns false if the workflow is not complete" do
      expect(workflow.complete?).to eq(false)
    end

    it "returns true if the workflow is complete" do
      workflow.complete

      expect(workflow.complete?).to eq(true)
    end
  end

  context "#reset_activity" do
    it "resets the current node" do
      workflow = described_class.new({ activity_id: 6, workflow_id: 2 }, api)

      workflow.reset_activity

      expect(api.find_activity_by_id(6)[:reset]).to eq(true)
    end
  end

  context "running activities" do
    let(:api) {
      Backbeat::MemoryApi.new(
        activities: {
          10 => { child_activities: [] },
          11 => { child_activities: [] }
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

    it "raises an error if there is not an activity id when running an activity" do
      workflow = described_class.new(workflow_data, api)

      expect { workflow.run_activity(action, :blocking, now) }.to raise_error Backbeat::Workflow::Remote::WorkflowError
    end

    it "registers a child node if there is an activity_id in the workflow data" do
      workflow = described_class.new({ activity_id: 10 }, api)

      workflow.run_activity(action, :non_blocking, now)

      activity_id = api.find_activity_by_id(10)[:child_activities].first
      activity = api.find_activity_by_id(activity_id)

      expect(activity).to eq(
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
