require "spec_helper"
require "support/memory_api"
require "backbeat/context/remote"
require "backbeat/contextable"

describe Backbeat::Contextable do

  class DoActivity
    include Backbeat::Contextable

    def do_something(x, y)
      x + y
    end
  end

  class Decider
    include Backbeat::Contextable

    def decision_one(a, b, c)
      DoActivity.in_context(current, :blocking).do_something(1, 2)
    end
  end

  let(:api) { Backbeat::MemoryApi.new({ events: { 1 => {} } }) }
  let(:remote_context) { Backbeat::Context::Remote.new({ event_id: 1 }, api) }
  let(:now) { Time.now }

  it "runs an activity in the set context" do
    Decider.in_context(remote_context, :blocking, now).decision_one(:one, :two, :three)
    event_id = api.find_event_by_id(1)[:child_events].first
    event = api.find_event_by_id(event_id)

    expect(event).to eq(
      {
        id: 2,
        name: "Decider.decision_one",
        mode: :blocking,
        fires_at: now,
        client_data: {
          action: {
            type: "Activity",
            name: "Decider.decision_one",
            class: Decider,
            method: :decision_one,
            args: [:one, :two, :three]
          }
        }
      }
    )
  end

  it "defaults to a local context if the context is not already set" do
    decider = Decider.new
    result = decider.decision_one(1, 2, 3)

    expect(result).to eq(3)
    expect(decider.context.event_history.last[:name]).to eq("DoActivity.do_something")
  end

  it "sets the mode to blocking" do
    Decider.in_context(remote_context).decision_one(:one, :two, :three)
    event_id = api.find_event_by_id(1)[:child_events].first
    event = api.find_event_by_id(event_id)

    expect(event[:mode]).to eq(:blocking)
  end

  it "sets the mode to non_blocking" do
    Decider.in_context(remote_context, :non_blocking).decision_one(:one, :two, :three)
    event_id = api.find_event_by_id(1)[:child_events].first
    event = api.find_event_by_id(event_id)

    expect(event[:mode]).to eq(:non_blocking)
  end

  it "sets the mode to fire_and_forget" do
    Decider.in_context(remote_context, :fire_and_forget).decision_one(:one, :two, :three)
    event_id = api.find_event_by_id(1)[:child_events].first
    event = api.find_event_by_id(event_id)

    expect(event[:mode]).to eq(:fire_and_forget)
  end

  it "signals the workflow with an action" do
    Decider.in_context(remote_context, :signal).decision_one(:one, :two, :three)
    signal = api.find_workflow_by_id(1)[:signals]["Decider.decision_one"]

    expect(signal[:name]).to eq("Decider.decision_one")
    expect(signal[:mode]).to eq(:blocking)
  end

  context "contextible model" do

    class MyModel
      include Backbeat::ContextableModel

      attr_reader :id, :name

      def initialize(attrs)
        @id = attrs[:id]
        @name = attrs[:name]
      end

      def self.find(id)
        new(id: id, name: "A findable object")
      end

      def update_attributes(attrs)
        MyModel.new({ id: id }.merge(attrs))
      end
    end

    let(:object) { MyModel.new(id: 10, name: "Lime") }

    it "runs activities on an findable instance of a class" do
      object.in_context(remote_context).update_attributes({ name: "Lemon" })
      event_id = api.find_event_by_id(1)[:child_events].first
      event = api.find_event_by_id(event_id)

      expect(event).to eq(
        {
          id: 2,
          name: "MyModel#update_attributes",
          mode: :blocking,
          fires_at: nil,
          client_data: {
            action: {
              type: "FindableActivity",
              name: "MyModel#update_attributes",
              class: MyModel,
              id: 10,
              method: :update_attributes,
              args: [{ name: "Lemon" }]
            }
          }
        }
      )
    end

    it "can run in a local context" do
      Backbeat.local do |context|
        result = object.in_context(context).update_attributes({ name: "Orange" })

        expect(result.name).to eq("Orange")
        expect(context.event_history.last[:name]).to eq("MyModel#update_attributes")
      end
    end
  end
end
