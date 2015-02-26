module Backbeat
  module Context
    class Local
      attr_reader :state

      def initialize(data, state = {})
        @data = data
        @state = state
      end

      def blocking(fires_at = nil)
        Registry.new(data, state)
      end

      def non_blocking(fires_at = nil)
        Registry.new(data, state)
      end

      def fire_and_forget(fires_at = nil)
        Registry.new(data, state)
      end

      def processing
        state[:events] ||= {}
        state[:events][event_id] ||= { statuses: [] }
        state[:events][event_id][:statuses] << :processing
      end

      def complete
        state[:events] ||= {}
        state[:events][event_id] ||= { statuses: [] }
        state[:events][event_id][:statuses] << :complete
      end

      def errored
        state[:events] ||= {}
        state[:events][event_id] ||= { statuses: [] }
        state[:events][event_id][:statuses] << :errored
      end

      def event_history
        state[:event_history]
      end

      def complete_workflow!
        state[:workflow_complete] = true
      end

      class Registry
        def initialize(data, state)
          @data = data
          @state = state
        end

        def run(activity)
          activity.run(Context.new(@data, @state))
        end
      end

      private

      attr_reader :data

      def event_id
        data[:event_id]
      end
    end
  end
end
