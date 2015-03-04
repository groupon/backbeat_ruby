require "surrogate"

module Backbeat
  class MockHttpClient
    Surrogate.endow self

    define(:get) do |path, options = {}|
    end

    define(:post) do |path, data, options = {}|
    end

    define(:put) do |path, data, options = {}|
    end
  end
end
