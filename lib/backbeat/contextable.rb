require "backbeat/action/activity"
require "backbeat/context/local"

module Backbeat
  module Contextable
    def context
      @context ||= Context::Local.new({})
    end

    def with_context(context)
      @context = context
      yield
    end

    def in_context(new_context, mode = :blocking, fires_at = nil)
      ContextProxy.new(self, new_context, { mode: mode, fires_at: fires_at })
    end

    private

    class ContextProxy
      def initialize(contextible, context, options)
        @contextible = contextible
        @context = context
        @mode = options[:mode] || :blocking
        @fires_at = options[:fires_at]
      end

      def method_missing(method, *args)
        activity = Action::Activity.build(
          build_name(method),
          contextible,
          method,
          args
        )
        if mode == :signal
          context.signal_workflow(activity, fires_at)
        else
          context.run_activity(activity, mode, fires_at)
        end
      end

      private

      attr_reader :contextible, :context, :mode, :fires_at

      def build_name(method)
        if contextible.is_a?(Class)
          "#{contextible.to_s}.#{method}"
        else
          "#{contextible.class.to_s}##{method}"
        end
      end
    end
  end
end
