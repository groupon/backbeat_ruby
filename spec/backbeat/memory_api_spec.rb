require "spec_helper"
require "surrogate/rspec"
require "support/mock_api"
require "support/memory_api"
require "backbeat/api"

describe Backbeat::MemoryApi do

  it "implements the backbeat api interface" do
    expect(Backbeat::MockApi).to substitute_for(Backbeat::Api)
    expect(Backbeat::MemoryApi).to substitute_for(Backbeat::MockApi)
  end

end
