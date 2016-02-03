require "spec_helper"
require "backbeat/handler"
require "backbeat"

describe Backbeat::Handler do

  class Cooking
    include Backbeat::Handler

    def chop(amount)
      register("cooking-workflow.activity-2").with(10)
      amount * 2
    end
    activity "cooking-workflow.activity-1", :chop

    def fry(a, b)
      register("cooking-workflow.last-activity").call
      (a + b) * 3
    end
    activity "cooking-workflow.activity-2", :fry

    def serve
      :done
    end
    activity "cooking-workflow.last-activity", :serve
  end

  let(:handlers) { Backbeat::Handler.__handlers__ }

  let(:store) { Backbeat::MemoryStore.new }

  before do
    Backbeat.configure do |config|
      config.context = :remote
      config.store = store
    end
  end

  it "registers activities" do
    expect(handlers["cooking-workflow.activity-1"]).to eq({
      class: Cooking,
      method: :chop
    })
  end

  it "raises an exception if the method does not exist" do
    expect {
      Cooking.activity("name", :foo)
    }.to raise_error(Backbeat::Handler::ActivityRegistrationError, "Method foo does not exist")
  end

  it "signals a workflow with the activity" do
    activity = Backbeat::Handler.signal("cooking-workflow.activity-1", "new subject").with(5)

    activity.run
    activity_data = store.find_workflow_by_id(1)[:signals]["cooking-workflow.activity-1"]

    expect(activity_data[:name]).to eq("cooking-workflow.activity-1")
    expect(activity_data[:mode]).to eq(:blocking)
    expect(activity_data[:client_data]).to eq({
      name: "cooking-workflow.activity-1",
      params: [5]
    })
    expect(activity.result).to eq(10)
  end

  it "signals a workflow with the activity" do
    parent_activity = Cooking.new.signal("cooking-workflow.activity-1", "new subject").with(5)

    activity = Backbeat::Handler.with_current_activity(parent_activity) do
      Backbeat::Handler.register("cooking-workflow.activity-2", :non_blocking).with(1, 2)
    end

    activity.run
    activity_data = store.find_activity_by_id(activity.id)

    expect(activity_data[:name]).to eq("cooking-workflow.activity-2")
    expect(activity_data[:mode]).to eq(:non_blocking)
    expect(activity_data[:client_data]).to eq({
      name: "cooking-workflow.activity-2",
      params: [1, 2]
    })
    expect(activity.result).to eq(9)
  end
end
