module Backbeat
  module Context
    class Local
      attr_reader :state

      def initialize(data, state = {})
        @data = data
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
        state[:event_history]
      end

      def complete_workflow!
        state[:workflow_complete] = true
      end

      def run_activity(action, mode, fires_at = nil)
        state[:event_history] ||= []
        action_hash = action.to_hash
        action_name = action_hash[:name]
        state[:event_history] << action_name
        new_data = data.merge(event_name: action_name)
        action.run(Local.new(new_data, state))
      end

      private

      attr_reader :data

      def event_name
        data[:event_name]
      end

      def add_event_status(status)
        state[:events] ||= {}
        state[:events][event_name] ||= { statuses: [] }
        state[:events][event_name][:statuses] << status
      end
    end
  end
end
