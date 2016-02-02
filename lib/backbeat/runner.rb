module Backbeat
  class Runner
    def self.chain
      @chain ||= Chain.new(
        RunActivity,
        LogActivity
      )
    end

    def initialize(config)
      @config = config
      @chain = Runner.chain
    end

    def call(activity, workflow)
      @chain.build do |chain, runner|
        runner.new(chain, @config)
      end.call(activity, workflow)
    end

    class LogActivity
      def initialize(chain, config)
        @chain = chain
        @logger = config.logger
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

    class RunActivity
      def initialize(chain, _)
        @chain = chain
      end

      def call(activity, workflow)
        activity.run
      end
    end

    class Chain
      def initialize(*entries)
        @entries = entries
        @base = Proc.new { |a, w| }
      end

      def add(klass)
        @entries << klass
      end

      def remove(klass)
        @entries.delete(klass)
      end

      def build
        @entries.reduce(@base) do |chain, runner|
          yield chain, runner
        end
      end
    end
  end
end
