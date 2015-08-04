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

      def activity_processing
        api.update_activity_status(activity_id, :processing)
      end

      def activity_completed(result)
        response = Packer.success_response(result)
        api.update_activity_status(activity_id, :completed, response)
      end

      def activity_errored(error)
        response = Packer.error_response(error)
        api.update_activity_status(activity_id, :errored, response)
      end

      def deactivate
        api.update_activity_status(activity_id, :deactivated)
      end

      def activity_history
        api.find_all_workflow_activities(id)
      end

      def complete?
        api.find_workflow_by_id(id)[:complete]
      end

      def complete
        api.complete_workflow(id)
      end

      def signal_workflow(action, fires_at = nil)
        activity_data = Packer.pack_action(action, :blocking, fires_at)
        api.signal_workflow(id, activity_data[:name], activity_data)
      end

      def run_activity(action, mode, fires_at = nil)
        activity_data = Packer.pack_action(action, mode, fires_at)
        api.add_child_activity(activity_id, activity_data)
      end

      def reset_activity
        api.reset_activity(activity_id)
      end

      private

      attr_reader :api, :current_node

      def activity_id
        current_node[:activity_id] || workflow_error("No activity id present in current workflow data")
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
