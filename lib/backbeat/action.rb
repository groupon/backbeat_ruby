module Backbeat
  class Action
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
    rescue
      workflow.errored
      raise
    end

    private

    attr_reader :workflowable, :method, :args
  end
end
