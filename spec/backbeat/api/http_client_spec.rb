require "spec_helper"
require "webmock/rspec"
require "backbeat/api/http_client"

describe Backbeat::API::HttpClient do
  let(:client) { Backbeat::API::HttpClient.new("backbeat.com", "987") }

  context "#get" do
    it "makes a get request to the backbeat host with the client id" do
      request = WebMock.stub_request(:get, "http://backbeat.com/events").with(
        headers: { "Authorization" => "Backbeat 987" }
      ).to_return({ status: 200, body: "Event", headers: { "header" => "something"}})

      response = client.get("/events")

      expect(request).to have_been_requested
      expect(response[:status]).to eq(200)
      expect(response[:body]).to eq("Event")
      expect(response[:headers]["header"]).to eq("something")
    end

    it "makes a get request with provided headers" do
      request = WebMock.stub_request(:get, "http://backbeat.com/events").with(
        headers: {
          "Authorization" => "Backbeat 987",
          "Accept" => "application/json"
        }
      )

      client.get("/events", headers: { "Accept" => "application/json"})

      expect(request).to have_been_requested
    end

    it "makes a get request with provided query params" do
      request = WebMock.stub_request(:get, "http://backbeat.com/events").with(
        headers: {
          "Authorization" => "Backbeat 987",
          "Accept" => "application/json"
        },
        query: { key: :value }
      )

      client.get("/events", {
        headers: { "Accept" => "application/json"},
        query: { key: :value }
      })

      expect(request).to have_been_requested
    end
  end

  context "#post" do
    it "makes a post request to the backbeat host with the client id" do
      request = WebMock.stub_request(:post, "http://backbeat.com/workflows").with(
        headers: { "Authorization" => "Backbeat 987" },
        body: "Data"
      ).to_return({ status: 201 })

      response = client.post("/workflows", "Data")

      expect(response[:status]).to eq(201)
      expect(request).to have_been_requested
    end

    it "makes a post request with the provided headers" do
      request = WebMock.stub_request(:post, "http://backbeat.com/workflows").with(
        headers: {
          "Authorization" => "Backbeat 987",
          "Content-Type" => "application/json"
        },
        body: "Data"
      )

      client.post("/workflows", "Data", headers: { "Content-Type" => "application/json" })

      expect(request).to have_been_requested
    end
  end

  context "#put" do
    it "makes a put request to the backbeat host with the client id" do
      request = WebMock.stub_request(:put, "http://backbeat.com/workflows").with(
        headers: { "Authorization" => "Backbeat 987" },
        body: "Data"
      ).to_return({ status: 200 })

      response = client.put("/workflows", "Data")

      expect(response[:status]).to eq(200)
      expect(request).to have_been_requested
    end

    it "makes a put request with the provided headers" do
      request = WebMock.stub_request(:put, "http://backbeat.com/workflows").with(
        headers: {
          "Authorization" => "Backbeat 987",
          "Content-Type" => "application/json"
        },
        body: "Data"
      )

      client.put("/workflows", "Data", headers: { "Content-Type" => "application/json" })

      expect(request).to have_been_requested
    end
  end
end
