require "spec_helper"
require "backbeat"
require "backbeat/packer"

describe Backbeat::Packer do
  let(:now) { Time.now }
  let(:memory_store) { Backbeat::MemoryStore.new }

  before do
    Backbeat.configure do |config|
      config.context = :remote
      config.store = memory_store
    end
  end

  context ".unpack_activity" do
    let(:activity_data) {{
      id: 1,
      client_data: {
        name: "activity name",
        class_name: "Array",
        method: "method",
        params: []
      }
    }}

    it "returns an activity object" do
      activity = Backbeat::Packer.unpack_activity(activity_data)

      expect(activity.id).to eq(activity_data[:id])
    end

    it "resolves the class name of the activity" do
      activity = Backbeat::Packer.unpack_activity(activity_data)

      expect(activity.to_hash[:client_data][:class]).to eq(Array)
    end
  end

  context ".unpack_workflow" do
    let(:activity_data) {{
      id: 1,
      workflow_name: "A workflow",
      workflow_id: 2,
      subject: "Subject",
      decider: "Decider",
      client_data: {
        name: "activity name",
        class_name: "Array",
        method: "method",
        params: []
      }
    }}

    it "returns a workflow object" do
      workflow = Backbeat::Packer.unpack_workflow(activity_data)

      expect(workflow.id).to eq(2)
    end

    it "builds the current activity with the workflow" do
      workflow = Backbeat::Packer.unpack_workflow(activity_data)

      expect(workflow.current_activity.id).to eq(1)
    end

    it "underscores keys" do
      camelized_data = activity_data.merge({ "clientData" => activity_data[:client_data] })
      workflow = Backbeat::Packer.unpack_workflow(camelized_data)

      expect(workflow.current_activity.id).to eq(1)
    end
  end

  context ".success_response" do
    it "builds a json-rpc compliant response with a result" do
      expect(Backbeat::Packer.success_response({ id: 1, name: "Lemon" })).to eq(
        {
          jsonrpc: "2.0",
          result: { id: 1, name: "Lemon" },
          error: nil,
          id: nil
        }
      )
    end
  end

  context ".error_response" do
    it "builds a json-rpc compliant response with an error" do
      begin
        raise "A test error"
      rescue => e
        error = e
      end

      response = Backbeat::Packer.error_response(error)

      expect(response[:result]).to be_nil
      expect(response[:id]).to be_nil
      expect(response[:error][:message]).to eq("A test error")
      expect(response[:error][:data].count).to eq(5)
    end
  end

  context ".subject_to_string" do
    it "returns a string subject" do
      expect(Backbeat::Packer.subject_to_string("Subject")).to eq("Subject")
    end

    it "converts a hash subject" do
      subject = { name: "Subject", id: 1 }
      expect(Backbeat::Packer.subject_to_string(subject)).to eq(subject.to_json)
    end

    ObjectWithId = Struct.new(:id)

    it "converts an object with an id" do
      subject = ObjectWithId.new(5)
      expect(Backbeat::Packer.subject_to_string(subject)).to eq({ id: 5, class: ObjectWithId }.to_json)
    end

    it "converts an object that responds to to_hash" do
      subject = Class.new { def to_hash; { a: 1 } end; }.new
      expect(Backbeat::Packer.subject_to_string(subject)).to eq({ a: 1 }.to_json)
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
