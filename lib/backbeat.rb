require "ostruct"

module Backbeat
  def self.configure
    yield config
  end

  def self.config
    @config ||= OpenStruct.new
  end

  def self.context
    config.context
  end
end
