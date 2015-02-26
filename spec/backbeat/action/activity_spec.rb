require "spec_helper"
require "backbeat/contextable"
require "backbeat/context/local"
require "backbeat/action/activity"

describe Backbeat::Action::Activity do

  class MyActivity
    extend Backbeat::Contextable

    def boom
      raise
    end

    def self.perform(a, b, c)
      a + b + c
    end
  end

  it "has a name" do
    action = described_class.new(name: "New Activity")

    expect(action.name).to eq("New Activity")
  end

  it "has a class" do
    action = described_class.new(class: MyActivity)

    expect(action.klass).to eq(MyActivity)
  end

  it "has a method" do
    action = described_class.new(method: :perform)

    expect(action.method).to eq(:perform)
  end

  it "has arguments" do
    action = described_class.new(args: [1, 2, 3])

    expect(action.args).to eq([1, 2, 3])
  end

  it "returns a hash representation of itself" do
    action = described_class.build("Blue", MyActivity, :perform, 1, 2, 3)

    expect(action.to_hash).to eq({
      type: "Activity",
      name: "Blue",
      class: MyActivity,
      method: :perform,
      args: [1, 2, 3]
    })
  end

  context "run" do
    let(:action) { described_class.build("Blue", MyActivity, :perform, 1, 2, 3) }

    let(:context) { Backbeat::Context::Local.new({ event_id: 10 }) }

    it "calls the method on the class with the arguments" do
      expect(action.run(context)).to eq(6)
    end

    it "sends a processing message to the context" do
      action.run(context)

      expect(context.state[:events][10][:statuses].first).to eq(:processing)
    end

    it "sends a complete message to the context" do
      action.run(context)

      expect(context.state[:events][10][:statuses].last).to eq(:complete)
    end

    it "sends an error message to the context on error" do
      action = described_class.build("Blue", MyActivity, :boom)

      action.run(context)

      expect(context.state[:events][10][:statuses].last).to eq(:errored)
    end
  end
end
