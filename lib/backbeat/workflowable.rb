require "backbeat/serializer/activity"
require "backbeat/serializer/findable_activity"

module Backbeat
  module Workflowable
    module InContext
      def in_context(workflow, mode = :blocking, fires_at = nil)
        ContextProxy.new(self, workflow, { mode: mode, fires_at: fires_at })
      end

      def start_context(subject)
        name = self.is_a?(Class) ? self.to_s : self.class.to_s
        workflow = Workflow.new({
          subject: subject,
          decider: name,
          name: name
        })
        ContextProxy.new(self, workflow, { mode: :signal })
      end

      def link_context(workflow, subject)
        other_workflow = Workflow.new({ subject: subject })
        link_id = workflow.activity_id
        options = { mode: :signal, link_id: link_id }
        ContextProxy.new(self, other_workflow, options)
      end

      def serializer
        Serializer::Activity
      end
    end

    def self.included(klass)
      klass.extend(InContext)
    end

    def workflow
      @workflow ||= Workflow.new({})
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
        @options = options
      end

      def method_missing(method, *params)
        activity = Activity.build(build_serializer(method, params))
        if options[:mode] == :signal
          workflow.signal_workflow(activity, options)
        else
          workflow.run_activity(activity, options)
        end
        workflow
      end

      private

      attr_reader :workflowable, :workflow, :options

      def build_serializer(method, params)
        workflowable.serializer.build(
          build_name(method),
          workflowable,
          method,
          params
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
