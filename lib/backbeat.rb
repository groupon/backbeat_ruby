require "backbeat/api"
require "backbeat/api/http_client"
require "backbeat/contextable"
require "backbeat/context/local"
require "backbeat/context/remote"
require "backbeat/packer"

module Backbeat
  class Config
    attr_accessor :context
    attr_accessor :host
    attr_accessor :client_id
    attr_accessor :api
  end

  class ConfigurationError < StandardError; end

  def self.configure
    @config = Config.new
    yield config
  end

  def self.config
    @config ||= Config.new
  end

  def self.context
    if config.context
      config.context
    else
      raise ConfigurationError.new("Context not configured")
    end
  end

  def self.api
    config.api ||= default_api
  end

  def self.default_api
    case context.name
    when Context::Remote.name
      Api.new(Api::HttpClient.new(config.host, config.client_id))
    when Context::Local.name
      {}
    else
      raise ConfigurationError.new("Unknown default api for context #{context}")
    end
  end

  def self.local
    yield Context::Local.new({})
  end
end
