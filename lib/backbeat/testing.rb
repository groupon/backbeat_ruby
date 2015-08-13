module Backbeat
  class Testing
    class << self
      attr_accessor :run_activities

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
