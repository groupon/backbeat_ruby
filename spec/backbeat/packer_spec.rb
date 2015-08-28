require "spec_helper"
require "backbeat/packer"
require "backbeat/serializer/activity"
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

  context ".pack_activity" do
    it "returns a the api representation of node data" do
      activity = Backbeat::Serializer::Activity.build("activity", "Klass", :method, [])
      activity_hash = activity.to_hash
      options = { mode: :blocking, fires_at: now }

      expect(Backbeat::Packer.pack_activity(activity, options)).to eq({
        name: activity_hash[:name],
        mode: :blocking,
        fires_at: now,
        client_data: activity_hash
      })
    end
  end

  context ".unpack_activity" do
    let(:serializer) {
      Backbeat::Serializer::Activity.build("activity name", Array, :method, [])
    }

    it "returns the activity object specified in the activity type with the activity data" do
      unpacked_activity = Backbeat::Packer.unpack_activity({
        client_data: {
          name: "activity name",
          serializer: "Backbeat::Serializer::Activity",
          class: "Array",
          method: :method,
          params: []
        }
      })

      expect(unpacked_activity.to_hash).to eq(serializer.to_hash)
    end

    it "resolves the class name of the activity" do
      unpacked_activity = Backbeat::Packer.unpack_activity({
        client_data: {
          name: "activity name",
          serializer: "Backbeat::Serializer::Activity",
          class: "Array",
          method: :method,
          params: []
        }
      })

      expect(unpacked_activity.to_hash).to eq(serializer.to_hash)
    end

    it "symbolizes the method name" do
      unpacked_activity = Backbeat::Packer.unpack_activity({
        client_data: {
          name: "activity name",
          serializer: "Backbeat::Serializer::Activity",
          class: "Array",
          method: "method",
          params: []
        }
      })

      expect(unpacked_activity.to_hash).to eq(serializer.to_hash)
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
