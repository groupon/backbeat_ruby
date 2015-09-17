require "multi_json"
require "securerandom"
require "backbeat/packer"

module Backbeat
  module Workflow
    class Local
      attr_reader :id

      def initialize(current_activity, state = {})
        @id = SecureRandom.uuid
        @current_activity = current_activity
        @state = state
        state[:activity_history] ||= []
        state[:activity_history] << current_activity
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
        new_activity = current_activity.merge({
          id: SecureRandom.uuid,
          name: activity_name,
          activity: activity_hash,
          statuses: [],
        })
        activity_runner = jsonify_activity(activity, options)
        new_workflow = Local.new(new_activity, state)
        activity_runner.run(new_workflow) if Testing.run_activities?
        new_activity
      end

      def activity_id
        current_activity[:id]
      end

      private

      attr_reader :current_activity, :state

      def jsonify_activity(activity, options)
        Packer.unpack_activity(
          MultiJson.load(
            MultiJson.dump(Packer.pack_activity(activity, options)),
            symbolize_keys: true
          )
        )
      end

      def activity_name
        current_activity[:name]
      end

      def add_activity_status(status, response = nil)
        current_activity[:statuses] ||= []
        if status == :deactivated
          activity_history.each { |activity| activity[:statuses] << :deactivated }
        else
          current_activity[:statuses] << status
        end
        current_activity[:response] = response
      end
    end
  end
end
