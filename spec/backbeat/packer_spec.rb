require "spec_helper"
require "backbeat/action/activity"
require "backbeat/packer"

describe Backbeat::Packer do
  let(:now) { Time.now }
  let(:api) { Backbeat::MemoryApi.new }

  before do
    Backbeat.configure do |config|
      config.context = Backbeat::Context::Remote
      config.api = api
    end
  end

  context "unpack_context" do
    it "returns a new instance of the configured context type" do
      Backbeat::Packer.unpack_context({ workflow_id: 1 }) do |context|
        context.complete_workflow!
      end

      expect(api.find_workflow_by_id(1)[:complete]).to eq(true)
    end
  end

  context "pack_action" do
    it "returns a the api representation of node data" do
      action = Backbeat::Action::Activity.build("Action", "Klass", :method, [])
      action_hash = action.to_hash

      expect(Backbeat::Packer.pack_action(action, :blocking, now)).to eq({
        name: action_hash[:name],
        mode: :blocking,
        fires_at: now,
        client_data: {
          action: action_hash
        }
      })
    end
  end

  context "unpack_action" do
    let(:action) {
      Backbeat::Action::Activity.build("Action name", Array, :method, [])
    }

    it "returns the action object specified in the action type with the action data" do
      unpacked_action = Backbeat::Packer.unpack_action({
        client_data: {
          action: {
            name: "Action name",
            type: "Activity",
            class: Array,
            method: :method,
            args: []
          }
        }
      })

      expect(unpacked_action.to_hash).to eq(action.to_hash)
    end

    it "resolves the class name of the action" do
      unpacked_action = Backbeat::Packer.unpack_action({
        client_data: {
          action: {
            name: "Action name",
            type: "Activity",
            class: "Array",
            method: :method,
            args: []
          }
        }
      })

      expect(unpacked_action.to_hash).to eq(action.to_hash)
    end

    it "symbolizes the method name" do
      unpacked_action = Backbeat::Packer.unpack_action({
        client_data: {
          action: {
            name: "Action name",
            type: "Activity",
            class: "Array",
            method: "method",
            args: []
          }
        }
      })

      expect(unpacked_action.to_hash).to eq(action.to_hash)
    end
  end

  context "continue" do

    class MyArray
      include Backbeat::Contextable

      def build(n)
        Array.new(n)
      end
    end

    it "continues the workflow from the context data" do
      action = Backbeat::Action::Activity.build("Action", MyArray, :build, [5])
      action_data = Backbeat::Packer.pack_action(action, :fire_and_forget, now)
      decision_data = action_data.merge(workflow_id: 1, id: 2)

      result = Backbeat::Packer.continue(decision_data)

      expect(result).to eq(Array.new(5))
    end
  end
end
