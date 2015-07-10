require "spec_helper"
require "backbeat/workflow"
require "backbeat/packer"
require "backbeat/workflowable"
require "backbeat/action"
require "backbeat/serializer/activity"

describe Backbeat::Workflow do

  context ".new" do
    it "returns the configured backbeat workflow type" do
      Backbeat.config.context = :remote
      workflow = Backbeat::Workflow.new({ name: "New Workflow", id: 1, workflow_id: 2 })
      workflow.processing

      expect(workflow).to be_a(Backbeat::Workflow::Remote)
      expect(Backbeat.api.find_event_by_id(1)[:status]).to eq(:processing)
    end
  end

  context ".continue" do

    class MyArray
      include Backbeat::Workflowable

      def build(n)
        Array.new(n)
      end
    end

    before do
      Backbeat.configure do |config|
        config.context = :local
      end
    end

    def build_action(name, workflowable, method, args)
      Backbeat::Action.new(Backbeat::Serializer::Activity.build(name, workflowable, method, args))
    end

    it "continues the workflow from the workflow data" do
      action = build_action("Action", MyArray, :build, [5])
      action_data = Backbeat::Packer.pack_action(action, :fire_and_forget)
      decision_data = action_data.merge(workflow_id: 1, id: 2)

      result = Backbeat::Workflow.continue(decision_data)

      expect(result).to eq(Array.new(5))
    end

    it "handles workflow data returned as a decision" do
      action = build_action("Action", MyArray, :build, [6])
      action_data = Backbeat::Packer.pack_action(action, :fire_and_forget)
      decision_data = action_data.merge(workflow_id: 1, id: 2)

      result = Backbeat::Workflow.continue({ "decision" => decision_data })

      expect(result).to eq(Array.new(6))
    end

    it "handles workflow data returned as an activity" do
      action = build_action("Action", MyArray, :build, [7])
      action_data = Backbeat::Packer.pack_action(action, :fire_and_forget)
      decision_data = action_data.merge(workflow_id: 1, id: 2)

      result = Backbeat::Workflow.continue({ "activity" => decision_data })

      expect(result).to eq(Array.new(7))
    end
  end
end
