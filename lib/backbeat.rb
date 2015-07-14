require "backbeat/api"
require "backbeat/api/http_client"
require "backbeat/workflowable"
require "backbeat/workflow"

module Backbeat
  class Config
    class ConfigurationError < StandardError; end

    attr_accessor :context
    attr_accessor :host
    attr_accessor :client_id
    attr_accessor :logger

    attr_writer :context
    def context
      @context || (
        raise ConfigurationError.new("Context not configured")
      )
    end

    attr_writer :api
    def api
      @api ||= (
        case context
        when :remote
          Api.new(Api::HttpClient.new(host, client_id))
        when :local
          {}
        else
          raise ConfigurationError.new("Unknown default api for context #{context}")
        end
      )
    end
  end

  def self.configure
    @config = Config.new
    yield config
    config
  end

  def self.config
    @config ||= Config.new
  end

  def self.local
    yield Workflow::Local.new({})
  end
end
