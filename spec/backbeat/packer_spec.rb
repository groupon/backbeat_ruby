require "spec_helper"
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
end
