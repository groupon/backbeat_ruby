require "spec_helper"
require "backbeat"
require "backbeat/testing"

describe Backbeat::Testing do

  class ImportWorkflow
    include Backbeat::Workflowable

    def import(thing)
      :import
      ImportWorkflow.in_context(workflow).finish("Imported")
    end

    def finish(message)
      message
    end
  end

  before do
    Backbeat.configure do |config|
      config.context = :local
    end

    Backbeat::Testing.enable!
    Backbeat::Testing.clear
  end

  after do
    Backbeat::Testing.disable!
  end

  it "adds activities to the testing queue rather than running" do
    ImportWorkflow.start_context({ id: 5 }).import("File")

    expect(Backbeat::Testing.activities.count).to eq(1)
    expect(Backbeat::Testing.activities.first.name).to eq("ImportWorkflow#import")
  end

  it "runs all queued activities" do
    ImportWorkflow.start_context({ id: 5 }).import("File")

    Backbeat::Testing.run

    store = Backbeat.config.store
    workflow = store.find_workflow_by_id(1)
    signal = workflow[:signals]["ImportWorkflow#import"]
    activity = store.find_activity_by_id(2)

    expect(signal[:statuses].last).to eq(:completed)
    expect(activity[:statuses].last).to eq(:completed)
    expect(activity[:response][:result]).to eq("Imported")
  end

  it "can run without starting a context" do
    ImportWorkflow.new.import("File")

    expect(Backbeat::Testing.activities.first.name).to eq("ImportWorkflow#finish")
    expect(Backbeat::Testing.activities.first.params).to eq(["Imported"])

    Backbeat::Testing.run

    store = Backbeat.config.store
    activity = store.find_activity_by_id(1)

    expect(activity[:statuses].last).to eq(:completed)
    expect(activity[:response][:result]).to eq("Imported")
  end
end
