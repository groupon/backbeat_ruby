require "spec_helper"
require "backbeat/workflowable"
require "backbeat/serializer/findable_activity"

describe Backbeat::Serializer::FindableActivity do

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

  let(:activity) {
    described_class.build("Yellow", object, :update_attributes, [{ name: "New name" }])
  }

  it "returns a hash representation of itself" do
    expect(activity.to_hash).to eq({
      serializer: "Backbeat::Serializer::FindableActivity",
      name: "Yellow",
      class: "MyModel",
      id: 4,
      method: :update_attributes,
      args: [{ name: "New name" }]
    })
  end

  it "returns the workflowable object" do
    expect(activity.workflowable).to be_a(MyModel)
    expect(activity.workflowable.id).to eq(4)
  end

  it "returns the method" do
    expect(activity.method).to eq(:update_attributes)
  end

  it "returns the args" do
    expect(activity.args).to eq([{ name: "New name" }])
  end
end
