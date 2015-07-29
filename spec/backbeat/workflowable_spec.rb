require "spec_helper"
require "support/memory_api"
require "backbeat/workflow/remote"
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

  let(:api) { Backbeat::MemoryApi.new({ events: { 1 => {} } }) }
  let(:remote_workflow) { Backbeat::Workflow::Remote.new({ event_id: 1 }, api) }
  let(:now) { Time.now }

  context ".in_context" do
    it "runs an activity in the set workflow" do
      Decider.in_context(remote_workflow, :blocking, now).decision_one(:one, :two, :three)
      event_id = api.find_event_by_id(1)[:child_events].first
      event = api.find_event_by_id(event_id)

      expect(event).to eq(
        {
          id: 2,
          name: "Decider#decision_one",
          mode: :blocking,
          type: :none,
          fires_at: now,
          client_data: {
            action: {
              serializer: "Backbeat::Serializer::Activity",
              name: "Decider#decision_one",
              class: "Decider",
              method: :decision_one,
              args: [:one, :two, :three]
            }
          }
        }
      )
    end

    it "sets the mode to blocking" do
      Decider.in_context(remote_workflow).decision_one(:one, :two, :three)
      event_id = api.find_event_by_id(1)[:child_events].first
      event = api.find_event_by_id(event_id)

      expect(event[:mode]).to eq(:blocking)
    end

    it "sets the mode to non_blocking" do
      Decider.in_context(remote_workflow, :non_blocking).decision_one(:one, :two, :three)
      event_id = api.find_event_by_id(1)[:child_events].first
      event = api.find_event_by_id(event_id)

      expect(event[:mode]).to eq(:non_blocking)
    end

    it "sets the mode to fire_and_forget" do
      Decider.in_context(remote_workflow, :fire_and_forget).decision_one(:one, :two, :three)
      event_id = api.find_event_by_id(1)[:child_events].first
      event = api.find_event_by_id(event_id)

      expect(event[:mode]).to eq(:fire_and_forget)
    end

    it "signals the workflow with an action" do
      Decider.in_context(remote_workflow, :signal).decision_one(:one, :two, :three)
      signal = api.find_workflow_by_id(1)[:signals]["Decider#decision_one"]

      expect(signal[:name]).to eq("Decider#decision_one")
      expect(signal[:mode]).to eq(:blocking)
    end
  end

  context ".start_context" do
    before do
      Backbeat.configure do |config|
        config.context = :remote
        config.api = api
      end
    end

    it "runs the activity on a new workflow for the subject" do
      subject = { id: 1, class: Array }

      Decider.start_context(subject).decision_one(:one, :two, :three)

      workflow = api.find_workflow_by_subject({ subject: subject.to_json })
      expect(workflow[:id]).to eq(1)
      expect(workflow[:name]).to eq("Decider")
      expect(workflow[:subject]).to eq(subject.to_json)
      expect(workflow[:signals].count).to eq(1)
    end
  end

  context "worklflowable model" do

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
      object.in_context(remote_workflow).update_attributes({ name: "Lemon" })
      event_id = api.find_event_by_id(1)[:child_events].first
      event = api.find_event_by_id(event_id)

      expect(event).to eq(
        {
          id: 2,
          name: "WorkflowableModel#update_attributes",
          mode: :blocking,
          type: :none,
          fires_at: nil,
          client_data: {
            action: {
              serializer: "Backbeat::Serializer::FindableActivity",
              name: "WorkflowableModel#update_attributes",
              class: "WorkflowableModel",
              id: 10,
              method: :update_attributes,
              args: [{ name: "Lemon" }]
            }
          }
        }
      )
    end

    it "can run in a local context" do
      Backbeat.local do |workflow|
        workflow = object.in_context(workflow).update_attributes({ name: "Orange" })

        expect(WorkflowableModel.find(10).name).to eq("Orange")
        expect(workflow.event_history.last[:name]).to eq("WorkflowableModel#update_attributes")
      end
    end
  end
end
