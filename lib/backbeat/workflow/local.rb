require "multi_json"
require "securerandom"
require "backbeat/packer"

module Backbeat
  module Workflow
    class Local
      attr_reader :id

      def initialize(current_node, state = {})
        @current_node = current_node
        @state = state
        @id = current_node[:workflow_id] ||= SecureRandom.uuid
      end

      def activity_processing
        add_activity_status(:processing)
      end

      def activity_completed(result)
        add_activity_status(:completed, { result: result })
      end

      def activity_errored(error)
        add_activity_status(:errored, { error: error.message })
      end

      def deactivate
        add_activity_status(:deactivated)
      end

      def activity_history
        state[:activity_history] ||= []
      end

      def complete?
        !!activity_history.find { |e| e[:name] == :workflow_complete }
      end

      def complete
        activity_history << { name: :workflow_complete }
      end

      def signal_workflow(action, fires_at = nil)
        run_activity(action, :blocking, fires_at)
      end

      def run_activity(action, mode, fires_at = nil)
        action_hash = action.to_hash
        action_name = action_hash[:name]
        activity_history << { name: action_name, action: action_hash }
        new_node = current_node.merge(activity_name: action_name)
        new_action = jsonify_action(action, mode, fires_at)
        new_action.run(Local.new(new_node, state))
      end

      private

      attr_reader :current_node, :state

      def jsonify_action(action, mode, fires_at)
        Packer.unpack_action(
          MultiJson.load(
            MultiJson.dump(Packer.pack_action(action, mode, fires_at)),
            symbolize_keys: true
          )
        )
      end

      def activity_name
        current_node[:activity_name]
      end

      def activity_record
        @activity_record ||= get_current_activity_record
      end

      def get_current_activity_record
        if activity = activity_history.find { |activity| activity[:name] == activity_name }
          activity
        else
          new_activity = { name: activity_name }
          activity_history << new_activity
          new_activity
        end
      end

      def add_activity_status(status, response = nil)
        activity_record[:statuses] ||= []
        if status == :deactivated
          activity_history.each { |activity| activity[:statuses] << :deactivated }
        else
          activity_record[:statuses] << status
        end
        activity_record[:response] = response
      end
    end
  end
end
