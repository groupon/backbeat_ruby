require "spec_helper"
require "support/memory_api"
require "backbeat/context/remote"
require "backbeat/contextable"

describe Backbeat::Contextable do

  class DoActivity
    extend Backbeat::Contextable

    def self.do_something(x, y)
    end
  end

  class Decider
    extend Backbeat::Contextable

    def self.decision_one(a, b, c)
      DoActivity.in_context(context, :blocking).do_something(1, 2)
    end
  end

  let(:api) { Backbeat::MemoryApi.new({}) }
  let(:remote_context) { Backbeat::Context::Remote.new({ event_id: 1 }, api) }
  let(:now) { Time.now }

  it "runs an activity in the set context" do
    Decider.in_context(remote_context, :blocking, now).decision_one(:one, :two, :three)

    expect(api.find_event_by_id(1)[:child_events].first).to eq(
      {
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
    Decider.decision_one(1, 2, 3)

    expect(Decider.context.event_history).to eq(["DoActivity.do_something"])
  end

  it "sets the mode to blocking" do
    Decider.in_context(remote_context).decision_one(:one, :two, :three)
    event = api.find_event_by_id(1)[:child_events].first

    expect(event[:mode]).to eq(:blocking)
  end

  it "sets the mode to non_blocking" do
    Decider.in_context(remote_context, :non_blocking).decision_one(:one, :two, :three)
    event = api.find_event_by_id(1)[:child_events].first

    expect(event[:mode]).to eq(:non_blocking)
  end

  it "sets the mode to fire_and_forget" do
    Decider.in_context(remote_context, :fire_and_forget).decision_one(:one, :two, :three)
    event = api.find_event_by_id(1)[:child_events].first

    expect(event[:mode]).to eq(:fire_and_forget)
  end

  it "signals the workflow with an action" do
    Decider.in_context(remote_context, :signal).decision_one(:one, :two, :three)
    signal = api.find_workflow_by_id(1)[:signals]["Decider.decision_one"]

    expect(signal[:name]).to eq("Decider.decision_one")
    expect(signal[:mode]).to eq(:blocking)
  end
end
