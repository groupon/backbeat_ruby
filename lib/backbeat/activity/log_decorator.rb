module Backbeat
  class Activity
    class LogDecorator
      def initialize(activity, logger)
        @activity = activity
        @logger = logger
      end

      def run(workflow)
        logger.info({ name: :activity_started, node: workflow })
        ret_val = activity.run(workflow)
        logger.info({ name: :activity_complete, node: workflow })
        ret_val
      rescue => e
        logger.error({ name: :activity_errored, error: e, node: workflow })
        raise
      end

      def to_hash
        activity.to_hash
      end

      private

      attr_reader :activity, :logger
    end
  end
end
