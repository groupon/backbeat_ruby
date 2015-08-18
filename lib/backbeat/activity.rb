require "backbeat/activity/log_decorator"

module Backbeat
  class Activity
    def self.build(serializer)
      activity = new(serializer)
      if logger = Backbeat.config.logger
        LogDecorator.new(activity, logger)
      else
        activity
      end
    end

    def initialize(serializer)
      @serializer = serializer
      @workflowable = serializer.workflowable
      @method = serializer.method
      @params = serializer.params
    end

    def run(workflow)
      ret_value = nil
      workflowable.with_context(workflow) do
        workflow.activity_processing
        ret_value = workflowable.send(method, *params)
        workflow.activity_completed(ret_value)
      end
      ret_value
    rescue => e
      workflow.activity_errored(e)
      raise e
    end

    def to_hash
      serializer.to_hash
    end

    private

    attr_reader :serializer, :workflowable, :method, :params

  end
end
