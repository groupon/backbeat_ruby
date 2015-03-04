module Backbeat
  module Context
    class Local
      def initialize(current_node, state = {})
        @current_node = current_node
        @state = state
      end

      def processing
        add_event_status(:processing)
      end

      def complete
        add_event_status(:complete)
      end

      def errored
        add_event_status(:errored)
      end

      def event_history
        state[:event_history] ||= []
      end

      def complete_workflow!
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
        action.run(Local.new(new_node, state))
      end

      private

      attr_reader :current_node, :state

      def event_name
        current_node[:event_name]
      end

      def event_record
        @event_record ||= event_history.last
      end

      def add_event_status(status)
        event_history << { name: event_name } if event_history.empty?
        event_record[:statuses] ||= []
        event_record[:statuses] << status
      end
    end
  end
end
