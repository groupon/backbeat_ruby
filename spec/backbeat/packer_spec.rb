require "spec_helper"
require "backbeat/packer"
require "backbeat/action/activity"
require "support/memory_api"

describe Backbeat::Packer do
  let(:now) { Time.now }
  let(:api) { Backbeat::MemoryApi.new }

  before do
    Backbeat.configure do |config|
      config.context = :remote
      config.api = api
    end
  end

  context ".unpack_workflow" do
    it "returns a new instance of the configured workflow type" do
      workflow = Backbeat::Packer.unpack_workflow({ workflow_id: 1 })
      workflow.complete_workflow!

      expect(api.find_workflow_by_id(1)[:complete]).to eq(true)
    end
  end

  context ".pack_action" do
    it "returns a the api representation of node data" do
      action = Backbeat::Action::Activity.build("Action", "Klass", :method, [])
      action_hash = action.to_hash

      expect(Backbeat::Packer.pack_action(action, :blocking, now)).to eq({
        name: action_hash[:name],
        mode: :blocking,
        type: :none,
        fires_at: now,
        client_data: {
          action: action_hash
        }
      })
    end
  end

  context ".unpack_action" do
    let(:action) {
      Backbeat::Action::Activity.build("Action name", Array, :method, [])
    }

    it "returns the action object specified in the action type with the action data" do
      unpacked_action = Backbeat::Packer.unpack_action({
        client_data: {
          action: {
            name: "Action name",
            type: "Backbeat::Action::Activity",
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
            type: "Backbeat::Action::Activity",
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
            type: "Backbeat::Action::Activity",
            class: "Array",
            method: "method",
            args: []
          }
        }
      })

      expect(unpacked_action.to_hash).to eq(action.to_hash)
    end
  end

  context ".underscore_keys" do
    it "converts camel cased keys to underscored keys" do
      data = { "fooBar" => [{"barBaz" => "baz"}]}
      expect(Backbeat::Packer.underscore_keys(data)).to eq(
        { foo_bar: [{ bar_baz: "baz" }]}
      )
    end
  end
end
