require "backbeat/contextable"
require "backbeat/context/local"
require "backbeat/context/remote"
require "backbeat/action/activity"
require "backbeat/packer"

module Backbeat
  def self.configure
    yield config
  end

  class Config
    attr_accessor :context
    attr_accessor :host
    attr_accessor :client_id
  end

  def self.config
    @config ||= Config.new
  end

  class ContextNotConfiguredError < StandardError; end

  def self.context
    if config.context
      config.context
    else
      raise ContextNotConfiguredError
    end
  end

  def self.local
    yield Context::Local.new({})
  end
end
