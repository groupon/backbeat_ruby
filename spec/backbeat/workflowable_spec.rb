require "spec_helper"
require "backbeat"
require "backbeat/memory_store"
require "backbeat/workflow"
require "backbeat/workflowable"

describe Backbeat::Workflowable do

  class DoActivity
    include Backbeat::Workflowable

    def do_something(x, y)
      x + y
    end
  end

  class Decider
    include Backbeat::Workflowable

    def decision_one(a, b, c)
      DoActivity.in_context(workflow, :blocking).do_something(1, 2)
    end
  end

  let(:store) {
    Backbeat::MemoryStore.new({
      activities: { 1 => {} },
      workflows: { 5 => {} }
    })
  }
  let(:activity) {
    Backbeat::Activity.new({ activity_data: { id: 1 } })
  }
  let(:workflow) {
    Backbeat::Workflow.new({
      workflow_data: { id: 5 },
      current_activity: activity
    })
  }
  let(:now) { Time.now }

  before do
    Backbeat.configure do |config|
      config.context = :remote
      config.store = store
    end
  end

  context ".in_context" do
    it "runs an activity in the set workflow" do
      Decider.in_context(workflow, :blocking, now).decision_one(:one, :two, :three)
      activity_id = store.find_activity_by_id(1)[:child_activities].first
      activity = store.find_activity_by_id(activity_id)

      expect(activity).to eq(
        {
          id: 2,
          name: "Decider#decision_one",
          mode: :blocking,
          fires_at: now,
          client_data: {
            class: Decider,
            class_name: "Decider",
            method: :decision_one,
            params: [:one, :two, :three]
          }
        }
      )
    end

    it "sets the mode to blocking" do
      Decider.in_context(workflow).decision_one(:one, :two, :three)
      activity_id = store.find_activity_by_id(1)[:child_activities].first
      activity = store.find_activity_by_id(activity_id)

      expect(activity[:mode]).to eq(:blocking)
    end

    it "sets the mode to non_blocking" do
      Decider.in_context(workflow, :non_blocking).decision_one(:one, :two, :three)
      activity_id = store.find_activity_by_id(1)[:child_activities].first
      activity = store.find_activity_by_id(activity_id)

      expect(activity[:mode]).to eq(:non_blocking)
    end

    it "sets the mode to fire_and_forget" do
      Decider.in_context(workflow, :fire_and_forget).decision_one(:one, :two, :three)
      activity_id = store.find_activity_by_id(1)[:child_activities].first
      activity = store.find_activity_by_id(activity_id)

      expect(activity[:mode]).to eq(:fire_and_forget)
    end

    it "signals the workflow with an activity" do
      Decider.in_context(workflow, :signal).decision_one(:one, :two, :three)
      signal = store.find_workflow_by_id(5)[:signals]["Decider#decision_one"]

      expect(signal[:name]).to eq("Decider#decision_one")
      expect(signal[:mode]).to eq(:signal)
    end

    it "returns the activity" do
      Backbeat.local do |workflow|
        activity = DoActivity.in_context(workflow, :signal).do_something(3, 4)

        expect(activity.result).to eq(7)
      end
    end
  end

  context ".start_context" do
    it "runs the activity on a new workflow for the subject" do
      subject = { id: 1, class: Array }

      Decider.start_context(subject).decision_one(:one, :two, :three)

      workflow = store.find_workflow_by_subject({ subject: subject.to_json })
      expect(workflow[:id]).to eq(6)
      expect(workflow[:name]).to eq("Decider")
      expect(workflow[:subject]).to eq(subject.to_json)
      expect(workflow[:signals].count).to eq(1)
    end
  end

  context ".link_context" do
    it "creates a signal activity with the current node linked" do
      subject = { id: 1, class: Array }

      Decider.link_context(workflow, subject).decision_one(:a, :b, :c)

      other_workflow = store.find_workflow_by_id(6)
      signal = other_workflow[:signals]["Decider#decision_one"]

      expect(other_workflow[:subject]).to eq(subject.to_json)
      expect(signal[:parent_link_id]).to eq(activity.id)
    end
  end

  context "WorkflowableModel" do

    class WorkflowableModel
      include Backbeat::WorkflowableModel

      def self.records
        @records ||= []
      end

      def self.find(id)
        records.fetch(id) do
          records[id] = new(id: id, name: "A findable object")
          records[id]
        end
      end

      attr_reader :id, :name

      def initialize(attrs)
        @id = attrs[:id]
        @name = attrs[:name]
      end

      def update_attributes(attrs)
        WorkflowableModel.records[id] = WorkflowableModel.new({ id: id }.merge(attrs))
      end
    end

    let(:object) { WorkflowableModel.new(id: 10, name: "Lime") }

    it "runs activities on an findable instance of a class" do
      object.in_context(workflow).update_attributes({ name: "Lemon" })
      activity_id = store.find_activity_by_id(1)[:child_activities].first
      activity = store.find_activity_by_id(activity_id)

      expect(activity).to eq(
        {
          id: 2,
          name: "WorkflowableModel#update_attributes",
          mode: :blocking,
          fires_at: nil,
          client_data: {
            class_name: "WorkflowableModel",
            class: WorkflowableModel,
            id: 10,
            method: :update_attributes,
            params: [{ name: "Lemon" }]
          }
        }
      )
    end

    it "can run in a local context" do
      Backbeat.local do |workflow|
        activity = object.in_context(workflow).update_attributes({ name: "Orange" })

        expect(WorkflowableModel.find(10).name).to eq("Orange")
        expect(activity.name).to eq("WorkflowableModel#update_attributes")
      end
    end
  end
end
