require "spec_helper"
require "backbeat/workflowable"
require "backbeat/workflow/local"
require "backbeat/action/findable_activity"

describe Backbeat::Action::FindableActivity do

  class MyModel
    include Backbeat::Workflowable

    attr_reader :id, :name

    def initialize(attrs)
      @id = attrs[:id]
      @name = attrs[:name]
    end

    def self.find(id)
      new(id: id, name: "An AR object")
    end

    def update_attributes(attrs)
      MyModel.new({ id: id }.merge(attrs))
    end
  end

  let(:object) { MyModel.new(id: 4, name: "A name") }

  it "returns a hash representation of itself" do
    action = described_class.build("Yellow", object, :update_attributes, [{ name: "New name" }])

    expect(action.to_hash).to eq({
      type: "Backbeat::Action::FindableActivity",
      name: "Yellow",
      class: "MyModel",
      id: 4,
      method: :update_attributes,
      args: [{ name: "New name" }]
    })
  end

  context "#run" do
    let(:action_hash) {
      described_class.build("Yellow", object, :update_attributes, [{ name: "New name" }]).to_hash
    }

    let(:action) { described_class.new(action_hash) }

    let(:workflow) { Backbeat::Workflow::Local.new({ event_name: "Yellow" }) }

    it "calls the method on the object with the arguments" do
      new_object = action.run(workflow)

      expect(new_object.id).to eq(4)
      expect(new_object.name).to eq("New name")
    end
  end
end
