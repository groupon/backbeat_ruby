require "spec_helper"
require "surrogate/rspec"
require "support/mock_http_client"
require "backbeat/api/http_client"

describe Backbeat::MockHttpClient do

  it "implements the backbeat http client interface" do
    expect(Backbeat::MockHttpClient).to substitute_for(Backbeat::Api::HttpClient)
  end

end
