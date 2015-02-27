require "spec_helper"

describe Backbeat::Context::Local do

  it "marks an event as processing" do
    context = described_class.new({ event_name: "First Event" })
    context.processing

    expect(context.state[:events]["First Event"][:statuses].last).to eq(:processing)
  end

  it "marks an event as complete" do
    context = described_class.new({ event_name: "First Event" })
    context.complete

    expect(context.state[:events]["First Event"][:statuses].last).to eq(:complete)
  end

  it "marks an event as errored" do
    context = described_class.new({ event_name: "First Event" })
    context.errored

    expect(context.state[:events]["First Event"][:statuses].last).to eq(:errored)
  end

  it "returns the workflow event history" do
    context = described_class.new({ event_name: "First Event" }, { event_history: [:one] })
    history = context.event_history

    expect(history).to eq([:one])
  end

  it "completes a workflow" do
    context = described_class.new({ event_name: "First Event" })
    context.complete_workflow!

    expect(context.state[:workflow_complete]).to eq(true)
  end

  class TheActivity
    extend Backbeat::Contextable

    def self.do_some_addition(a, b, c)
      answer = a + b + c
      [answer, context]
    end
  end

  context "registering actions" do
    let(:context) { described_class.new({ event_name: "First Event", workflow_id: 2 }) }
    let(:now) { Time.now }

    it "Runs a workflow locally, now" do
      action = Backbeat::Actors::Activity.build("Adding", TheActivity, :do_some_addition, [10, 11, 12])

      value, new_context = context.now.run(action)

      expect(value).to eq(33)
      expect(new_context.state[:event_history]).to eq(["Adding"])
      expect(new_context.state[:events]["Adding"][:statuses].last).to eq(:complete)
    end

    [:blocking, :non_blocking, :fire_and_forget].each do |event_type|

      it "Returns a #{event_type} registry that runs the action now" do
        registry = context.send(event_type, now)
        action = Backbeat::Actors::Activity.build("Adding", TheActivity, :do_some_addition, [10, 11, 12])

        value, context = registry.run(action)

        expect(value).to eq(33)
        expect(context.state[:event_history]).to eq(["Adding"])
        expect(context.state[:events]["Adding"][:statuses].last).to eq(:complete)
      end

    end
  end
end
