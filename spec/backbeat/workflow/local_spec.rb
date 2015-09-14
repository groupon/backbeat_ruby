require "spec_helper"
require "backbeat/workflowable"
require "backbeat/serializer/activity"
require "backbeat/workflow/local"

describe Backbeat::Workflow::Local do

  context "#activity_history" do
    it "returns the workflow activity history" do
      workflow = described_class.new({ name: "First activity" }, { activity_history: [:one] })
      history = workflow.activity_history

      expect(history).to eq([:one, { name: "First activity" }])
    end
  end

  context "#activity_processing" do
    it "marks an activity as processing" do
      workflow = described_class.new({ name: "First activity" })
      workflow.activity_processing

      activity = workflow.activity_history.first
      expect(activity[:name]).to eq("First activity")
      expect(activity[:statuses]).to eq([:processing])
    end
  end

  context "#activity_completed" do
    it "marks an activity as completed" do
      workflow = described_class.new({ name: "First activity" })
      workflow.activity_completed(100)

      activity = workflow.activity_history.first
      expect(activity[:statuses]).to eq([:completed])
      expect(activity[:response][:result]).to eq(100)
    end
  end

  context "#activity_errored" do
    it "marks an activity as errored" do
      workflow = described_class.new({ name: "First activity" })
      error = StandardError.new("Boom")
      workflow.activity_errored(error)

      activity = workflow.activity_history.first
      expect(activity[:statuses]).to eq([:errored])
      expect(activity[:response][:error]).to eq("Boom")
    end
  end

  context "#deactivate" do
    it "marks an activity and previous activities as deactivated" do
      workflow = described_class.new(
        { name: "Second activity" },
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
      workflow = described_class.new({ name: "First activity" })
      workflow.complete

      expect(workflow.activity_history.last[:name]).to eq(:workflow_complete)
    end
  end

  context "#complete?" do
    let(:workflow) { described_class.new({ name: "An activity" }) }

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
      answer
    end

    def return_the_arg(arg)
      arg
    end
  end

  context "running activities" do
    let(:workflow) { described_class.new({ name: "First activity" }) }
    let(:now) { Time.now }

    it "runs a workflow locally" do
      activity = Backbeat::Activity.new(
        Backbeat::Serializer::Activity.build("Adding", TheActivity, :do_some_addition, [10, 11, 12])
      )

      activity_data = workflow.run_activity(activity, { mode: :blocking })

      expect(activity_data[:response][:result]).to eq(33)
      expect(activity_data[:name]).to eq("Adding")
      expect(activity_data[:activity]).to eq(activity.to_hash)
      expect(activity_data[:statuses].last).to eq(:completed)
      expect(Backbeat::Testing.activity_history.last[:name]).to eq("Adding")
    end

    it "runs the workflow locally on signal_workflow" do
      activity = Backbeat::Activity.new(
        Backbeat::Serializer::Activity.build("MATH", TheActivity, :do_some_addition, [3, 2, 1])
      )

      activity_data = workflow.signal_workflow(activity, { fires_at: now })

      expect(activity_data[:response][:result]).to eq(6)
      expect(activity_data[:name]).to eq("MATH")
      expect(activity_data[:activity]).to eq(activity.to_hash)
      expect(activity_data[:statuses].last).to eq(:completed)
    end

    it "json parses the activity arguments to ensure proper expectations during testing" do
      activity = Backbeat::Serializer::Activity.build("Compare symbols", TheActivity, :return_the_arg, [:orange])

      activity_data = workflow.run_activity(activity, { mode: :blocking })

      expect(activity_data[:response][:result]).to eq("orange")
    end

    it "does not run the activity if disabled" do
      activity = Backbeat::Serializer::Activity.build("Compare symbols", TheActivity, :return_the_arg, [:orange])

      begin
        Backbeat::Testing.disable_activities!
        activity_data = workflow.run_activity(activity, { mode: :blocking })

        expect(activity_data[:response]).to eq(nil)
      ensure
        Backbeat::Testing.enable_activities!
      end
    end

    it "adds the activity to the testing event history" do
      Backbeat::Testing.clear!

      activity = Backbeat::Serializer::Activity.build("Adding", TheActivity, :do_some_addition, [10, 11, 12])

      workflow.run_activity(activity, { mode: :blocking })

      expect(Backbeat::Testing.activity_history.last[:name]).to eq("Adding")
    end
  end
end
