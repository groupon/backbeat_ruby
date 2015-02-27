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
      DoActivity.in_context_blocking(context).do_something(1, 2)
    end
  end

  let(:api) { Backbeat::MemoryApi.new({}) }
  let(:remote_context) { Backbeat::Context::Remote.new({ event_id: 1 }, api) }
  let(:now) { Time.now }

  it "runs an activity in the set context" do
    Decider.in_context(
      remote_context, { mode: :blocking, name: "Deciding", fires_at: now }
    ).decision_one(:one, :two, :three)

    expect(api.find_event_by_id(1)[:child_events].first).to eq(
      {
        name: "Deciding",
        mode: :blocking,
        fires_at: now,
        client_data: {
          action: {
            type: "Activity",
            name: "Deciding",
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
    Decider.in_context_blocking(remote_context).decision_one(:one, :two, :three)
    event = api.find_event_by_id(1)[:child_events].first

    expect(event[:mode]).to eq(:blocking)
  end

  it "sets the mode to non_blocking" do
    Decider.in_context_non_blocking(remote_context).decision_one(:one, :two, :three)
    event = api.find_event_by_id(1)[:child_events].first

    expect(event[:mode]).to eq(:non_blocking)
  end

  it "sets the mode to fire_and_forget" do
    Decider.in_context_fire_forget(remote_context).decision_one(:one, :two, :three)
    event = api.find_event_by_id(1)[:child_events].first

    expect(event[:mode]).to eq(:fire_and_forget)
  end
end
