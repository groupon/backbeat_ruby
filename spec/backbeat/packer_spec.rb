require "spec_helper"
require "backbeat/action/activity"
require "backbeat/packer"

describe Backbeat::Packer do
  let(:now) { Time.now }

  context "pack_action" do
    it "returns a the api representation of node data" do
      action = Backbeat::Action::Activity.build("Action", "Klass", :method, args: [])

      expect(Backbeat::Packer.pack_action(action, :blocking, now)).to eq({
        name: action.name,
        mode: :blocking,
        fires_at: now,
        client_data: {
          action: action.to_hash
        }
      })
    end
  end

  context "unpack_action" do
    it "returns the actor object specified in the action type with the action data" do
      action = Backbeat::Action::Activity.build("Action", "Klass", :method, args: [])
      action_data = Backbeat::Packer.pack_action(action, :fire_and_forget, now)
      unpacked_action = Backbeat::Packer.unpack_action(action_data)

      expect(unpacked_action.to_hash).to eq(action.to_hash)
    end
  end
end
