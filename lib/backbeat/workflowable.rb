require "backbeat/action/activity"
require "backbeat/action/findable_activity"
require "backbeat/workflow/local"

module Backbeat
  module Workflowable

    module InContext
      def in_context(workflow, mode = :blocking, fires_at = nil)
        ContextProxy.new(self, workflow, { mode: mode, fires_at: fires_at })
      end

      def action
        Action::Activity
      end
    end

    def self.included(klass)
      klass.extend(InContext)
    end

    def workflow
      @workflow ||= Workflow::Local.new({})
    end

    def with_context(workflow)
      @workflow = workflow
      yield
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
        activity = workflowable.action.build(
          build_name(method),
          workflowable,
          method,
          args
        )
        if mode == :signal
          workflow.signal_workflow(activity, fires_at)
        else
          workflow.run_activity(activity, mode, fires_at)
        end
      end

      private

      attr_reader :workflowable, :workflow, :mode, :fires_at

      def build_name(method)
        if workflowable.is_a?(Class)
          "#{workflowable.to_s}.#{method}"
        else
          "#{workflowable.class.to_s}##{method}"
        end
      end
    end
  end

  module WorkflowableModel
    include Workflowable
    include Workflowable::InContext

    def action
      Action::FindableActivity
    end
  end
end
