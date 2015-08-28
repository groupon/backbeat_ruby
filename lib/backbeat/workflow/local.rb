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
        state[:activity_history] ||= []
        Testing.activity_history = state[:activity_history]
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
        state[:activity_history]
      end

      def complete?
        !!activity_history.find { |e| e[:name] == :workflow_complete }
      end

      def complete
        activity_history << { name: :workflow_complete }
      end

      def signal_workflow(activity, options)
        run_activity(activity, options.merge({ mode: :blocking }))
      end

      def run_activity(activity, options)
        activity_hash = activity.to_hash
        activity_name = activity_hash[:name]
        activity_history << { name: activity_name, activity: activity_hash }
        new_node = current_node.merge({ activity_name: activity_name, activity_id: SecureRandom.uuid })
        new_activity = jsonify_activity(activity, options)
        new_activity.run(Local.new(new_node, state)) if Testing.run_activities?
      end

      def activity_id
        current_node[:activity_id]
      end

      private

      attr_reader :current_node, :state

      def jsonify_activity(activity, options)
        Packer.unpack_activity(
          MultiJson.load(
            MultiJson.dump(Packer.pack_activity(activity, options)),
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
