require "spec_helper"
require "backbeat/workflow"
require "backbeat/packer"
require "backbeat/workflowable"
require "backbeat/activity"
require "backbeat/serializer/activity"
require "support/memory_api"

describe Backbeat::Workflow do

  context ".new" do
    it "returns the configured backbeat workflow type" do
      Backbeat.configure do |config|
        config.context = :remote
        config.host = 'backbeat'
        config.client_id = 'backbeat'
        config.api = Backbeat::MemoryApi.new({})
      end

      workflow = Backbeat::Workflow.new({ name: "New Workflow", id: 1, workflow_id: 2 })

      workflow.activity_processing

      expect(workflow).to be_a(Backbeat::Workflow::Remote)
      expect(Backbeat.config.api.find_activity_by_id(1)[:status]).to eq(:processing)
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

    def build_activity(name, workflowable, method, args)
      Backbeat::Activity.new(Backbeat::Serializer::Activity.build(name, workflowable, method, args))
    end

    it "continues the workflow from the workflow data" do
      activity = build_activity("activity", MyArray, :build, [5])
      activity_data = Backbeat::Packer.pack_activity(activity, :fire_and_forget)
      decision_data = activity_data.merge(workflow_id: 1, id: 2)

      result = Backbeat::Workflow.continue(decision_data)

      expect(result).to eq(Array.new(5))
    end

    it "handles workflow data returned as a decision" do
      activity = build_activity("activity", MyArray, :build, [6])
      activity_data = Backbeat::Packer.pack_activity(activity, :fire_and_forget)
      decision_data = activity_data.merge(workflow_id: 1, id: 2)

      result = Backbeat::Workflow.continue({ "decision" => decision_data })

      expect(result).to eq(Array.new(6))
    end

    it "handles workflow data returned as an activity" do
      activity = build_activity("activity", MyArray, :build, [7])
      activity_data = Backbeat::Packer.pack_activity(activity, :fire_and_forget)
      decision_data = activity_data.merge(workflow_id: 1, id: 2)

      result = Backbeat::Workflow.continue({ "activity" => decision_data })

      expect(result).to eq(Array.new(7))
    end
  end
end
