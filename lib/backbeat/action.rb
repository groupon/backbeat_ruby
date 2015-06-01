require "backbeat/logging"

module Backbeat
  class Action
    include Logging

    def initialize(workflowable, method, args)
      @workflowable = workflowable
      @method = method
      @args = args
    end

    def run(workflow)
      ret_value = nil
      logger.info({ name: :action_started, node: workflow })
      workflowable.with_context(workflow) do
        workflow.processing
        ret_value = workflowable.send(method, *args)
        workflow.complete
      end
      logger.info({ name: :action_complete, node: workflow })
      ret_value
    rescue => e
      logger.error({ name: :action_errored, error: e, node: workflow })
      workflow.errored
      raise
    end

    private

    attr_reader :workflowable, :method, :args
  end
end
