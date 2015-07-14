require "backbeat/serializer/activity"
require "backbeat/serializer/findable_activity"

module Backbeat
  module Workflowable
    module InContext
      def in_context(workflow, mode = :blocking, fires_at = nil)
        ContextProxy.new(self, workflow, { mode: mode, fires_at: fires_at })
      end

      def serializer
        Serializer::Activity
      end
    end

    def self.included(klass)
      klass.extend(InContext)
    end

    def workflow
      @workflow
    end

    def with_context(current_workflow)
      @workflow = current_workflow
      yield
    ensure
      @workflow = nil
    end

    private

    class ContextProxy
      def initialize(workflowable, workflow, options)
        @workflowable = workflowable
        @workflow = workflow
        @mode = options[:mode]
        @fires_at = options[:fires_at]
      end

      def method_missing(method, *args)
        action = Action.build(build_serializer(method, args))
        if mode == :signal
          workflow.signal_workflow(action, fires_at)
        else
          workflow.run_activity(action, mode, fires_at)
        end
      end

      private

      attr_reader :workflowable, :workflow, :mode, :fires_at

      def build_serializer(method, args)
        workflowable.serializer.build(
          build_name(method),
          workflowable,
          method,
          args
        )
      end

      def build_name(method)
        if workflowable.is_a?(Class)
          "#{workflowable.to_s}##{method}"
        else
          "#{workflowable.class.to_s}##{method}"
        end
      end
    end
  end

  module WorkflowableModel
    include Workflowable
    include Workflowable::InContext

    def serializer
      Serializer::FindableActivity
    end
  end
end
