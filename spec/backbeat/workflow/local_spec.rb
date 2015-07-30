require "spec_helper"
require "backbeat/workflowable"
require "backbeat/serializer/activity"
require "backbeat/workflow/local"

describe Backbeat::Workflow::Local do

  context "#activity_history" do
    it "returns the workflow activity history" do
      workflow = described_class.new({ activity_name: "First activity" }, { activity_history: [:one] })
      history = workflow.activity_history

      expect(history).to eq([:one])
    end
  end

  context "#activity_processing" do
    it "marks an activity as processing" do
      workflow = described_class.new({ activity_name: "First activity" })
      workflow.activity_processing

      activity = workflow.activity_history.first
      expect(activity[:name]).to eq("First activity")
      expect(activity[:statuses]).to eq([:processing])
    end
  end

  context "#activity_completed" do
    it "marks an activity as completed" do
      workflow = described_class.new({ activity_name: "First activity" })
      workflow.activity_completed

      activity = workflow.activity_history.first
      expect(activity[:statuses]).to eq([:completed])
    end
  end

  context "#activity_errored" do
    it "marks an activity as errored" do
      workflow = described_class.new({ activity_name: "First activity" })
      workflow.activity_errored

      activity = workflow.activity_history.first
      expect(activity[:statuses]).to eq([:errored])
    end
  end

  context "#deactivate" do
    it "marks an activity and previous activities as deactivated" do
      workflow = described_class.new(
        { activity_name: "Second activity" },
        { activity_history: [{ name: "First activity", statuses: [] }] }
      )
      workflow.deactivate

      workflow.activity_history.each do |activity|
        expect(activity[:statuses]).to eq([:deactivated])
      end
    end
  end

  context "#complete" do
    it "completes a workflow" do
      workflow = described_class.new({ activity_name: "First activity" })
      workflow.complete

      expect(workflow.activity_history.last[:name]).to eq(:workflow_complete)
    end
  end

  context "#complete?" do
    let(:workflow) { described_class.new({ activity_name: "An activity" }) }

    it "returns false if the workflow is not complete" do
      expect(workflow.complete?).to eq(false)
    end

    it "returns true if the workflow is complete" do
      workflow.complete

      expect(workflow.complete?).to eq(true)
    end
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
    let(:workflow) { described_class.new({ activity_name: "First activity", workflow_id: 2 }) }
    let(:now) { Time.now }

    it "runs a workflow locally" do
      action = Backbeat::Serializer::Activity.build("Adding", TheActivity, :do_some_addition, [10, 11, 12])

      value, new_workflow = workflow.run_activity(action, :blocking)
      activity = workflow.activity_history.last

      expect(value).to eq(33)
      expect(activity[:name]).to eq("Adding")
      expect(activity[:action]).to eq(action.to_hash)
      expect(activity[:statuses].last).to eq(:completed)
    end

    it "runs the workflow locally on signal_workflow" do
      action = Backbeat::Serializer::Activity.build("MATH", TheActivity, :do_some_addition, [3, 2, 1])

      value, new_workflow = workflow.signal_workflow(action, now)
      activity = workflow.activity_history.last

      expect(value).to eq(6)
      expect(activity[:name]).to eq("MATH")
      expect(activity[:action]).to eq(action.to_hash)
      expect(activity[:statuses].last).to eq(:completed)
    end

    it "json parses the action arguments to ensure proper expectations during testing" do
      action = Backbeat::Serializer::Activity.build("Compare symbols", TheActivity, :return_the_arg, [:orange])

      value, new_workflow = workflow.run_activity(action, :blocking)

      expect(value).to eq("orange")
    end
  end
end
