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

      def event_processing
        add_event_status(:processing)
      end

      def event_completed
        add_event_status(:completed)
      end

      def event_errored
        add_event_status(:errored)
      end

      def deactivate
        add_event_status(:deactivated)
      end

      def event_history
        state[:event_history] ||= []
      end

      def complete?
        !!event_history.find { |e| e[:name] == :workflow_complete }
      end

      def complete
        event_history << { name: :workflow_complete }
      end

      def signal_workflow(action, fires_at = nil)
        run_activity(action, :blocking, fires_at)
      end

      def run_activity(action, mode, fires_at = nil)
        action_hash = action.to_hash
        action_name = action_hash[:name]
        event_history << { name: action_name, action: action_hash }
        new_node = current_node.merge(event_name: action_name)
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

      def event_name
        current_node[:event_name]
      end

      def event_record
        @event_record ||= get_current_event_record
      end

      def get_current_event_record
        if event = event_history.find { |event| event[:name] == event_name }
          event
        else
          new_event = { name: event_name }
          event_history << new_event
          new_event
        end
      end

      def add_event_status(status)
        event_record[:statuses] ||= []
        if status == :deactivated
          event_history.each { |event| event[:statuses] << :deactivated }
        else
          event_record[:statuses] << status
        end
      end
    end
  end
end
