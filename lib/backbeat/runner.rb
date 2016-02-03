module Backbeat
  class Runner
    def self.chain
      @chain ||= Chain.new(LogActivity)
    end

    def initialize(logger)
      @logger = logger
    end

    def with_workflow(workflow)
      current = @workflow
      @workflow = workflow
      yield
    ensure
      @workflow = current
    end

    def running(activity)
      Runner.chain.build(@logger) do
        yield
      end.call(activity, @workflow)
    end

    class LogActivity
      def initialize(chain, logger)
        @chain = chain
        @logger = logger
      end

      def call(activity, workflow)
        logger.info(event(activity, :activity_started))
        ret_val = @chain.call(activity, workflow)
        logger.info(event(activity, :activity_complete))
        ret_val
      rescue => e
        logger.error(event(activity, :activity_errored))
      end

      private

      attr_reader :logger

      def event(activity, name)
        { name: name, activity: activity.name, params: activity.params }
      end
    end

    class Chain
      def initialize(*entries)
        @entries = entries
      end

      def add(klass)
        @entries << klass
      end

      def remove(klass)
        @entries.delete(klass)
      end

      def build(logger, &block)
        @entries.reduce(block) do |chain, runner|
          runner.new(chain, logger)
        end
      end
    end
  end
end
