require "spec_helper"
require "backbeat/action"
require "backbeat/serializer/activity"
require "backbeat/workflowable"
require "support/mock_logger"

describe Backbeat::Action do

  class MyWorkflowable
    include Backbeat::Workflowable

    def boom
      raise
    end

    def perform(a, b, c)
      a + b + c
    end
  end

  let(:workflow) { Backbeat::Workflow::Local.new({ event_name: "Maths" }) }
  let(:serializer) {
    Backbeat::Serializer::Activity.new({
      name: "An Action",
      class: MyWorkflowable,
      method: :perform,
      args: [1, 2, 3]
    })
  }

  let(:action) { described_class.new(serializer) }

  context "#run" do
    it "calls the method on the workflowable object with the arguments" do
      expect(action.run(workflow)).to eq(6)
    end

    it "sends a processing message to the workflow" do
      action.run(workflow)
      event = workflow.event_history.last

      expect(event[:name]).to eq("Maths")
      expect(event[:statuses].first).to eq(:processing)
    end

    it "sends a complete message to the workflow" do
      action.run(workflow)
      event = workflow.event_history.last

      expect(event[:name]).to eq("Maths")
      expect(event[:statuses].last).to eq(:completed)
    end

    it "sends an error message to the workflow on error" do
      serializer = Backbeat::Serializer::Activity.new({
        workflowable: MyWorkflowable,
        method: :boom,
        args: []
      })
      action = described_class.new(serializer)

      expect { action.run(workflow) }.to raise_error

      event = workflow.event_history.last

      expect(event[:name]).to eq("Maths")
      expect(event[:statuses].last).to eq(:errored)
    end
  end

  context "#to_hash" do
    it "returns the serializer as a hash" do
      action = described_class.new(serializer)
      expect(action.to_hash).to eq(serializer.to_hash)
    end
  end

  context ".build" do
    let(:serializer) {
      Backbeat::Serializer::Activity.new({
        name: "An Other Action",
        class: MyWorkflowable,
        method: :perform,
        args: [10, 11, 12]
      })
    }

    it "returns a log decorator if a logger is configured" do
      logger = Backbeat::MockLogger.new
      Backbeat.config.logger = logger
      action = described_class.build(serializer)

      action.run(workflow)

      expect(logger.msgs[:info].count).to eq(2)
    end

    it "returns the action without the decorator if a logger is not configured" do
      Backbeat.config.logger = nil
      action = described_class.build(serializer)

      expect(action).to be_a(Backbeat::Action)
    end
  end
end
