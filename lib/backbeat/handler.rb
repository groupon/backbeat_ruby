module Backbeat
  module Handler
    ActivityRegistrationError = Class.new(StandardError)

    extend self

    def self.__handlers__
      @__handlers__ ||= {}
    end

    def self.find(activity_name)
      __handlers__[activity_name]
    end

    def self.included(klass)
      klass.extend(Registration)
    end

    ACTIVITY = :backbeat_activity

    def current_activity
      Thread.current[ACTIVITY]
    end

    def with_current_activity(activity)
      previous = Thread.current[ACTIVITY]
      Thread.current[ACTIVITY] = activity
      yield
    ensure
      Thread.current[ACTIVITY] = previous
    end

    def register(activity_name, mode = :blocking)
      ActivityBuilder.new(activity_name, mode)
    end

    class ActivityBuilder
      attr_reader :name, :mode

      def initialize(name, mode)
        @name = name
        @mode = mode
      end

      def call(*params)
        activity = Activity.new({
          name: name,
          mode: mode,
          name: name,
          params: params,
          client_data: { name: name }
        }.merge(Handler.find(name)))
        Handler.current_activity.register_child(activity)
      end
      alias_method :with, :call
    end

    def signal(activity_name, subject)
      SignalBuilder.new(activity_name, subject)
    end

    class SignalBuilder
      attr_reader :name, :subject

      def initialize(name, subject)
        @name = name
        @subject = subject
      end

      def call(*params)
        workflow = Workflow.new({
          subject: subject,
          decider: name,
          name: name
        })
        activity = Activity.new({
          name: name,
          mode: :blocking,
          name: name,
          params: params,
          client_data: { name: name }
        }.merge(Handler.find(name)))
        workflow.signal(activity)
      end
      alias_method :with, :call
    end

    module Registration
      def activity(activity_name, method_name)
        klass = self
        if klass.method_defined?(method_name)
          Handler.__handlers__[activity_name] = {
            class: klass,
            method: method_name
          }
        else
          raise ActivityRegistrationError, "Method #{method_name} does not exist"
        end
      end
    end

    class CurrentActivityRunner
      def initialize(chain, _)
        @chain = chain
      end

      def call(activity, workflow)
        Handler.with_current_activity(activity) do
          @chain.call(activity, workflow)
        end
      end
    end
    Runner.chain.add(CurrentActivityRunner)
  end
end
