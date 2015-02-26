require "spec_helper"
require "support/memory_api"
require "backbeat/context/remote/registry"

describe Backbeat::Context::Remote::Registry do
  let(:api) {
    MemoryApi.new(
      events: {
        10 => { child_events: [] },
        11 => { child_events: [] }
      },
      workflows: {
        1 => { signals: {} }
      }
    )
  }
end
