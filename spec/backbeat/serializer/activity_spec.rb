require "spec_helper"
require "backbeat/workflowable"
require "backbeat/serializer/activity"

describe Backbeat::Serializer::Activity do

  class MyActivity
    include Backbeat::Workflowable

    def boom
      raise
    end

    def perform(a, b, c)
      a + b + c
    end
  end

  let(:activity) { described_class.build("Blue", MyActivity, :perform, [1, 2, 3]) }

  it "returns a hash representation of itself" do
    expect(activity.to_hash).to eq({
      serializer: "Backbeat::Serializer::Activity",
      name: "Blue",
      class: "MyActivity",
      method: :perform,
      args: [1, 2, 3]
    })
  end

  it "returns the workflowable class" do
    expect(activity.workflowable).to be_a(MyActivity)
  end

  it "returns the method" do
    expect(activity.method).to eq(:perform)
  end

  it "returns the args" do
    expect(activity.args).to eq([1, 2, 3])
  end
end
