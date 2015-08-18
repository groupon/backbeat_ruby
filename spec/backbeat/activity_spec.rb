require "spec_helper"
require "backbeat/activity"
require "backbeat/serializer/activity"
require "backbeat/workflowable"
require "backbeat/workflow/local"
require "support/mock_logger"

describe Backbeat::Activity do

  class MyWorkflowable
    include Backbeat::Workflowable

    def boom
      raise
    end

    def perform(a, b, c)
      workflow.complete
      a + b + c
    end

    def finish
    end
  end

  let(:workflow) { Backbeat::Workflow::Local.new({ activity_name: "Maths" }) }
  let(:serializer) {
    Backbeat::Serializer::Activity.new({
      name: "An activity",
      class: MyWorkflowable,
      method: :perform,
      params: [1, 2, 3]
    })
  }

  let(:activity) { described_class.new(serializer) }

  context "#run" do
    it "calls the method on the workflowable object with the arguments" do
      expect(activity.run(workflow)).to eq(6)
    end

    it "sends a processing message to the workflow" do
      activity.run(workflow)
      activity = workflow.activity_history.first

      expect(activity[:name]).to eq("Maths")
      expect(activity[:statuses].first).to eq(:processing)
    end

    it "sends a complete message with the result to the workflow" do
      activity.run(workflow)
      activity = workflow.activity_history.first

      expect(activity[:name]).to eq("Maths")
      expect(activity[:statuses].last).to eq(:completed)
      expect(activity[:response][:result]).to eq(6)
    end

    it "sends an error message to the workflow on error" do
      serializer = Backbeat::Serializer::Activity.new({
        class: MyWorkflowable,
        method: :boom,
        params: []
      })
      activity = described_class.new(serializer)

      expect { activity.run(workflow) }.to raise_error

      activity = workflow.activity_history.last

      expect(activity[:name]).to eq("Maths")
      expect(activity[:statuses].last).to eq(:errored)
    end
  end

  context "#to_hash" do
    it "returns the serializer as a hash" do
      activity = described_class.new(serializer)
      expect(activity.to_hash).to eq(serializer.to_hash)
    end
  end

  context ".build" do
    let(:serializer) {
      Backbeat::Serializer::Activity.new({
        name: "An Other activity",
        class: MyWorkflowable,
        method: :perform,
        params: [10, 11, 12]
      })
    }

    it "returns a log decorator if a logger is configured" do
      logger = Backbeat::MockLogger.new
      Backbeat.config.logger = logger
      activity = described_class.build(serializer)

      activity.run(workflow)

      expect(logger.msgs[:info].count).to eq(2)
    end

    it "returns the activity without the decorator if a logger is not configured" do
      Backbeat.config.logger = nil
      activity = described_class.build(serializer)

      expect(activity).to be_a(Backbeat::Activity)
    end
  end
end
