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

  context "signal" do
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

    it "handles the fires_at option for the signal" do
      tomorrow = Time.now + 60 * 60 * 24
      activity = Backbeat::Handler.signal(
        "cooking-workflow.activity-1",
        "new subject",
        { fires_at: tomorrow }
      ).with(5)

      activity_data = store.find_workflow_by_id(1)[:signals]["cooking-workflow.activity-1"]

      expect(activity_data[:fires_at]).to eq(tomorrow)
    end

    it "handles the client_id option for the signal" do
      activity = Backbeat::Handler.signal(
        "cooking-workflow.other-activity",
        "new subject",
        { client_id: "123" }
      ).with(5)

      activity_data = store.find_workflow_by_id(1)[:signals]["cooking-workflow.other-activity"]

      expect(activity_data[:client_id]).to eq("123")
    end
  end

  context "activity" do
    let(:parent_activity) {
      Cooking.new.signal("cooking-workflow.activity-1", "new subject").with(5)
    }

    it "registers and activity in an existing workflow" do
      activity = Backbeat::Handler.with_current_activity(parent_activity) do
        Backbeat::Handler.register("cooking-workflow.activity-2", mode: :non_blocking).with(1, 2)
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

    it "handles the client_id option" do
      activity = Backbeat::Handler.with_current_activity(parent_activity) do
        Backbeat::Handler.register("cooking-workflow.activity-12", client_id: 'abc').with(1, 2)
      end

      activity_data = store.find_activity_by_id(activity.id)

      expect(activity_data[:client_id]).to eq('abc')
    end

    it "handles the fires_at option" do
      today = Time.now

      activity = Backbeat::Handler.with_current_activity(parent_activity) do
        Backbeat::Handler.register("cooking-workflow.activity-2", fires_at: today).with(1, 2)
      end

      activity_data = store.find_activity_by_id(activity.id)

      expect(activity_data[:fires_at]).to eq(today)
    end
  end
end
