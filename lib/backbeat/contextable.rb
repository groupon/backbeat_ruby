require "backbeat/actors/activity"
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

    def in_context(context, options = {})
      ContextProxy.new(self, context, options)
    end

    def in_context_blocking(context, fires_at = nil)
      in_context(context, { mode: :blocking, fires_at: fires_at })
    end

    def in_context_non_blocking(context, fires_at = nil)
      in_context(context, { mode: :non_blocking, fires_at: fires_at })
    end

    def in_context_fire_forget(context, fires_at = nil)
      in_context(context, { mode: :fire_and_forget, fires_at: fires_at })
    end

    private

    class ContextProxy
      def initialize(contextible, context, options)
        @contextible = contextible
        @context = context
        @name = options[:name]
        @mode = options[:mode] || :blocking
        @fires_at = options[:fires_at]
      end

      def method_missing(method, *args)
        activity = Actors::Activity.build(
          name || build_name(method),
          contextible,
          method,
          args
        )
        context.run_activity(activity, mode, fires_at)
      end

      private

      attr_reader :contextible, :context, :name, :mode, :fires_at

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
