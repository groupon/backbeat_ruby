module Backbeat
  class Action
    attr_reader :contextible, :method, :args

    def initialize(contextible, method, args)
      @contextible = contextible
      @method = method
      @args = args
    end

    def run(context)
      ret_value = nil
      contextible.with_context(context) do
        context.processing
        ret_value = contextible.send(method, *args)
        context.complete
      end
      ret_value
    rescue
      context.errored
      raise
    end
  end
end
