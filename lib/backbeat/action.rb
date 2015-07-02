module Backbeat
  class Action
    def self.build(workflowable, method, args)
      action = new(workflowable, method, args)
      if logger = Backbeat.config.logger
        LogDecorator.new(action, logger)
      else
        action
      end
    end

    def initialize(workflowable, method, args)
      @workflowable = workflowable
      @method = method
      @args = args
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

    private

    attr_reader :workflowable, :method, :args
  end
end
