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

    def in_context(new_context, options = {})
      ContextProxy.new(self, new_context, options)
    end

    def in_context_blocking(new_context, fires_at = nil)
      in_context(new_context, { mode: :blocking, fires_at: fires_at })
    end

    def in_context_non_blocking(new_context, fires_at = nil)
      in_context(new_context, { mode: :non_blocking, fires_at: fires_at })
    end

    def in_context_fire_forget(new_context, fires_at = nil)
      in_context(new_context, { mode: :fire_and_forget, fires_at: fires_at })
    end

    def in_context_signal(new_context, fires_at = nil)
      in_context(new_context, { mode: :blocking, fires_at: fires_at, signal: true })
    end

    private

    class ContextProxy
      def initialize(contextible, context, options)
        @contextible = contextible
        @context = context
        @name = options[:name]
        @mode = options[:mode] || :blocking
        @fires_at = options[:fires_at]
        @signal = options[:signal]
      end

      def method_missing(method, *args)
        activity = Action::Activity.build(
          name || build_name(method),
          contextible,
          method,
          args
        )
        if signal
          context.signal_workflow(activity, fires_at)
        else
          context.run_activity(activity, mode, fires_at)
        end
      end

      private

      attr_reader :contextible, :context, :name, :mode, :fires_at, :signal

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
