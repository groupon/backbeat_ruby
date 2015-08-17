module Backbeat
  class Testing
    class << self
      attr_writer :activity_history

      def activity_history
        @activity_history ||= []
      end

      def clear!
        self.activity_history = []
      end

      def disable_activities!
        @run_activities = false
      end

      def enable_activities!
        @run_activities = true
      end

      def run_activities?
        @run_activities.nil? || @run_activities == true
      end
    end
  end
end
