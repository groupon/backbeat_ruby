require "backbeat/packer"

module Backbeat
  module Workflow
    class Remote
      attr_reader :id

      def initialize(current_node, api)
        @current_node = current_node
        @api = api
        @id = current_node[:workflow_id] || get_workflow_for_subject[:id]
      end

      def event_processing
        api.update_event_status(event_id, :processing)
      end

      def event_completed
        api.update_event_status(event_id, :completed)
      end

      def event_errored
        api.update_event_status(event_id, :errored)
      end

      def deactivate
        api.update_event_status(event_id, :deactivated)
      end

      def event_history
        api.find_all_workflow_events(id)
      end

      def complete?
        api.find_workflow_by_id(id)[:complete]
      end

      def complete
        api.complete_workflow(id)
      end

      def signal_workflow(action, fires_at = nil)
        event_data = Packer.pack_action(action, :blocking, fires_at)
        api.signal_workflow(id, event_data[:name], event_data)
      end

      def run_activity(action, mode, fires_at = nil)
        event_data = Packer.pack_action(action, mode, fires_at)
        api.add_child_event(event_id, event_data)
      end

      def reset_event
        api.reset_event(event_id)
      end

      private

      attr_reader :api, :current_node

      def event_id
        current_node[:event_id] || workflow_error("No event id present in current workflow data")
      end

      def get_workflow_for_subject
        api.find_workflow_by_subject(current_node) || api.create_workflow(current_node)
      end

      class WorkflowError < StandardError; end

      def workflow_error(message)
        raise WorkflowError.new(message)
      end
    end
  end
end
