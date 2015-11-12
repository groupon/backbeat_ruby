require "spec_helper"
require "surrogate/rspec"
require "support/mock_api"
require "backbeat/api"
require "backbeat/memory_store"

describe Backbeat::MemoryStore do

  it "implements the backbeat api interface" do
    expect(Backbeat::MockAPI).to substitute_for(Backbeat::API)
    expect(Backbeat::MemoryStore).to substitute_for(Backbeat::MockAPI)
  end

end
