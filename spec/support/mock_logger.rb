module Backbeat
  class MockLogger
    def info(msg)
      msgs[:info] << msg
    end

    def error(msg)
      msgs[:error] << msg
    end

    def msgs
      @msgs ||= Hash.new { |h, k| h[k] = [] }
    end
  end
end
