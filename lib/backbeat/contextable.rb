module Backbeat
  module Contextable
    class NoContextError < StandardError
    end

    def context
      if @context
        @context
      else
        raise NoContextError
      end
    end

    def with_context(context)
      @context = context
      yield self
    ensure
      @context = nil
    end
  end
end
