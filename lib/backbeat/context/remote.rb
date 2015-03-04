require "backbeat/packer"

module Backbeat
  module Context
    class Remote
      def initialize(current_node, api)
        @current_node = current_node
        @api = api
      end

      def processing
        api.update_event_status(event_id, :processing)
      end

      def complete
        api.update_event_status(event_id, :complete)
      end

      def errored
        api.update_event_status(event_id, :errored)
      end

      def event_history
        api.find_all_workflow_events(workflow_id)
      end

      def complete_workflow!
        api.complete_workflow(workflow_id)
      end

      def signal_workflow(action, fires_at = nil)
        event_data = build_event_data(action, :blocking, fires_at)
        api.signal_workflow(workflow_id, event_data[:name], event_data)
      end

      def run_activity(action, mode, fires_at = nil)
        event_data = build_event_data(action, mode, fires_at)
        api.add_child_event(event_id, event_data)
      end

      private

      attr_reader :api, :current_node

      def event_id
        current_node[:event_id] || context_error("No event id present in current context")
      end

      def workflow_id
        @workflow_id ||= current_node[:workflow_id] || get_workflow_for_subject[:id]
      end

      def get_workflow_for_subject
        api.find_workflow_by_subject(current_node) || api.create_workflow(current_node)
      end

      def build_event_data(action, mode, fires_at)
        Packer.pack_action(action, mode, fires_at)
      end

      class ContextError < StandardError; end

      def context_error(message)
        raise ContextError.new(message)
      end
    end
  end
end
