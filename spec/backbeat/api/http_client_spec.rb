# Copyright (c) 2015, Groupon, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# Neither the name of GROUPON nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
