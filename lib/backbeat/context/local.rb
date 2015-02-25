module Backbeat
  module Context
    class Local
      def initialize(data, state = {})
        @data = data
        @state = state
      end

      def deciding(event_id)
      end

      def complete(event_id)
      end

      def errored(event_id)
      end

      def deactivate(event_id)
      end

      def signal(data)
      end

      def add_children(event_id, data)
      end

      def add_activity(event_id, data)
      end

      def event_history(workflow_id)
      end

      def complete_workflow!(workflow_id)
      end
    end
  end
end
