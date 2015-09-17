require "backbeat/packer"

module Backbeat
  module Workflow
    class Remote
      attr_reader :id

      def initialize(current_activity, api)
        @current_activity = current_activity
        @api = api
        @id = current_activity[:workflow_id] || get_workflow_for_subject[:id]
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

      def signal_workflow(activity, options = {})
        activity_data = Packer.pack_activity(activity, options.merge({ mode: :blocking }))
        api.signal_workflow(id, activity_data[:name], activity_data)
      end

      def run_activity(activity, options)
        activity_data = Packer.pack_activity(activity, options)
        api.add_child_activity(activity_id, activity_data)
      end

      def reset_activity
        api.reset_activity(activity_id)
      end

      def activity_id
        current_activity[:id] || workflow_error("No activity id present in current workflow data")
      end

      private

      attr_reader :api, :current_activity

      def get_workflow_for_subject
        workflow_data = current_activity.merge({
          subject: Packer.subject_to_string(current_activity[:subject])
        })
        api.find_workflow_by_subject(workflow_data) || api.create_workflow(workflow_data)
      end

      class WorkflowError < StandardError; end

      def workflow_error(message)
        raise WorkflowError.new(message)
      end
    end
  end
end
