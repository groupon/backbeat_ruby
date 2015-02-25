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

  def self.build_subject(data)
    data[:subject]
  end

  def self.build_performer(data)
    data[:name].constantize
  end

  def self.build_context(data)
    context.build(data)
  end

  def self.signal(data)
    context.signal(data)
  end
end
