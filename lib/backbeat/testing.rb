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
        @activities_disabled = true
      end

      def disabled
        disable_activities!
        yield
      ensure
        enable_activities!
      end

      def enable_activities!
        @activities_disabled = false
      end

      def run_activities?
        !@activities_disabled
      end
    end
  end
end
