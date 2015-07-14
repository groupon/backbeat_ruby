module Backbeat
  class Action
    class LogDecorator
      def initialize(action, logger)
        @action = action
        @logger = logger
      end

      def run(workflow)
        logger.info({ name: :action_started, node: workflow })
        ret_val = action.run(workflow)
        logger.info({ name: :action_complete, node: workflow })
        ret_val
      rescue => e
        logger.error({ name: :action_errored, error: e, node: workflow })
        raise
      end

      def to_hash
        action.to_hash
      end

      private

      attr_reader :action, :logger
    end
  end
end
