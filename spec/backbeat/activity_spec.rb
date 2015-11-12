require "spec_helper"
require "backbeat"
require "backbeat/activity"
require "backbeat/workflowable"

describe Backbeat::Activity do

  class MyWorkflowable
    include Backbeat::Workflowable

    attr_accessor :id
    def self.find(id)
      x = new
      x.id = id
      x
    end

    def boom(*args)
      raise "Failed"
    end

    def perform(a, b, c)
      a + b + c
    end

    def finish
      workflow.complete
    end
  end

  let(:store) {
    Backbeat::MemoryStore.new(
      activities: {
        10 => {},
        11 => {}
      },
      workflows: {
        1 => { activities: [:activity_1, :activity_2, :activity_3] },
        2 => { complete: false }
      }
    )
  }

  let(:config) {
    config = Backbeat::Config.new
    config.context = :remote
    config.store = store
    config
  }

  let(:activity_data) {
    {
      id: 11,
      name: "MyActivity",
      mode: "blocking",
      client_data: {
        class: MyWorkflowable,
        method: "perform",
        params: [1, 2, 3]
      }
    }
  }
  let(:activity) {
    Backbeat::Activity.new({
      activity_data: activity_data,
      config: config
    })
  }

  let(:workflow) {
    Backbeat::Workflow.new({
      workflow_data: { id: 1, name: "MyWorkflow" },
      current_activity: activity,
      config: config
    })
  }

  context "#run" do
    it "calls the method on the workflowable object with the arguments" do
      expect_any_instance_of(MyWorkflowable).to receive(:perform).with(1, 2, 3)

      activity.run(workflow)
    end

    it "sets the workflow context on the worflowable object" do
      activity_data[:client_data][:method] = :finish
      activity_data[:client_data][:params] = []

      activity.run(workflow)

      expect(workflow.complete?).to eq(true)
    end

    it "sends a processing message to the activity" do
      activity.run(workflow)

      activity_record = store.find_activity_by_id(activity.id)

      expect(activity_record[:statuses].first).to eq(:processing)
    end

    it "sends a complete message with the result to the workflow" do
      activity.run(workflow)

      activity_record = store.find_activity_by_id(activity.id)

      expect(activity_record[:statuses].last).to eq(:completed)
      expect(activity.result).to eq(6)
    end

    it "sends an error message to the workflow on error" do
      activity_data[:client_data][:method] = :boom

      expect { activity.run(workflow) }.to raise_error RuntimeError, "Failed"

      activity_record = store.find_activity_by_id(activity.id)

      expect(activity_record[:statuses].last).to eq(:errored)
      expect(activity.error[:message]).to eq("Failed")
    end

    it "finds the workflowable object if an id is included" do
      activity_data[:client_data][:id] = 5
      activity_data[:client_data][:method] = :id
      activity_data[:client_data][:params] = []

      activity.run(workflow)
      activity_record = store.find_activity_by_id(activity.id)

      expect(activity_record[:statuses].last).to eq(:completed)
      expect(activity.result).to eq(5)
    end
  end

  context "#register_child" do
    let(:new_activity) {
      Backbeat::Activity.new({
        activity_data: {
          name: "SubActivity",
          mode: "blocking",
          client_data: {
            class: MyWorkflowable,
            method: "perform",
            params: [10, 10, 10]
          }
        },
        config: config
      })
    }

    it "registers a child activity" do
      activity.register_child(new_activity)

      registered_activity_id = store.find_activity_by_id(activity.id)[:child_activities].first
      activity_data = store.find_activity_by_id(registered_activity_id)

      expect(activity_data).to eq(new_activity.to_hash.merge({ id: 12 }))
    end

    it "sets the id on the child activity" do
      activity.register_child(new_activity)

      expect(new_activity.id).to eq(12)
    end
  end

  context "#to_hash" do
    it "returns the activity data" do
      expect(activity.to_hash).to eq(activity_data)
    end
  end
end
