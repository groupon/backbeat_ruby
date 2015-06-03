require "spec_helper"
require "backbeat/workflow"
require "backbeat/packer"
require "backbeat/workflowable"
require "backbeat/action/activity"

describe Backbeat::Workflow do

  context "continue" do

    class MyArray
      include Backbeat::Workflowable

      def build(n)
        Array.new(n)
      end
    end

    it "continues the workflow from the workflow data" do
      action = Backbeat::Action::Activity.build("Action", MyArray, :build, [5])
      action_data = Backbeat::Packer.pack_action(action, :fire_and_forget)
      decision_data = action_data.merge(workflow_id: 1, id: 2)

      result = Backbeat::Workflow.continue(decision_data)

      expect(result).to eq(Array.new(5))
    end

    it "handles workflow data returned as a decision" do
      action = Backbeat::Action::Activity.build("Action", MyArray, :build, [6])
      action_data = Backbeat::Packer.pack_action(action, :fire_and_forget)
      decision_data = action_data.merge(workflow_id: 1, id: 2)

      result = Backbeat::Workflow.continue({ "decision" => decision_data })

      expect(result).to eq(Array.new(6))
    end

    it "handles workflow data returned as an activity" do
      action = Backbeat::Action::Activity.build("Action", MyArray, :build, [7])
      action_data = Backbeat::Packer.pack_action(action, :fire_and_forget)
      decision_data = action_data.merge(workflow_id: 1, id: 2)

      result = Backbeat::Workflow.continue({ "activity" => decision_data })

      expect(result).to eq(Array.new(7))
    end
  end
end
