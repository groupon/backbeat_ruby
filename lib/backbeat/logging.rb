require "backbeat"
require "logger"

module Backbeat
  module Logging
    def logger
      @logger ||= init_logger
    end

    private

    def init_logger
      Backbeat.config.logger ||= Logger.new("/dev/null")
    end
  end
end
