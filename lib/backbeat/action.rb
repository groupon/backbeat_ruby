module Backbeat
  class Action
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

    private

    attr_reader :contextible, :method, :args
  end
end
