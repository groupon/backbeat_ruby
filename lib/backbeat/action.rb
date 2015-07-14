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
      @workflowable = serializer.workflowable
      @method = serializer.method
      @args = serializer.args
    end

    def run(workflow)
      ret_value = nil
      workflowable.with_context(workflow) do
        workflow.event_processing
        ret_value = workflowable.send(method, *args)
        workflow.event_completed
      end
      ret_value
    rescue => e
      workflow.event_errored
      raise
    end

    def to_hash
      serializer.to_hash
    end

    private

    attr_reader :serializer, :workflowable, :method, :args
  end
end
