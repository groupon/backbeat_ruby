require "backbeat/action/log_decorator"

module Backbeat
  class Action
    def self.build(serializer)
      action = new(serializer)
      if logger = Backbeat.config.logger
        LogDecorator.new(action, logger)
      else
        action
      end
    end

    def initialize(serializer)
      @serializer = serializer
    end

    def run(workflow)
      ret_value = nil
      workflowable.with_context(workflow) do
        workflow.processing
        ret_value = workflowable.send(method, *args)
        workflow.complete
      end
      ret_value
    rescue => e
      workflow.errored
      raise
    end

    def to_hash
      serializer.to_hash
    end

    private

    attr_reader :serializer

    def workflowable
      serializer.workflowable
    end

    def method
      serializer.method
    end

    def args
      serializer.args
    end
  end
end
