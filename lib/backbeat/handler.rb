module Backbeat
  module Handler
    ActivityRegistrationError = Class.new(StandardError)

    extend self

    def self.__handlers__
      @__handlers__ ||= {}
    end

    def self.add(activity_name, klass, method_name)
      __handlers__[activity_name] = {
        class: klass,
        method: method_name
      }
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

    def register(activity_name, options = {})
      ActivityBuilder.new(activity_name, options)
    end

    class ActivityBuilder
      attr_reader :name, :options, :parent

      def initialize(name, options)
        @name = name
        @options = options
        @parent = Handler.current_activity
      end

      def call(*params)
        run_data = Handler.find(name) || {}

        activity = Activity.new({
          config: parent.config,
          name: name,
          mode: options[:mode],
          fires_at: options[:fires_at],
          client_id: client_id(options),
          params: params,
          client_data: { name: name }
        }.merge(run_data))

        parent.register_child(activity)
      end
      alias_method :with, :call

      def client_id(options)
        if id = options[:client_id]
          id
        elsif client_name = options[:client]
          parent.config.client(client_name)
        end
      end
    end

    def signal(activity_name, subject, options = {})
      SignalBuilder.new(activity_name, subject, options)
    end

    class SignalBuilder
      attr_reader :name, :subject, :options

      def initialize(name, subject, options)
        @name = name
        @subject = subject
        @options = options
      end

      def call(*params)
        workflow = Workflow.new({
          config: options[:config],
          subject: subject,
          decider: name,
          name: name
        })

        run_data = Handler.find(name) || {}

        activity = Activity.new({
          config: workflow.config,
          name: name,
          mode: :blocking,
          fires_at: options[:fires_at],
          client_id: client_id(workflow, options),
          params: params,
          client_data: { name: name }
        }.merge(run_data))

        workflow.signal(activity)
      end
      alias_method :with, :call

      def client_id(workflow, options)
        if id = options[:client_id]
          id
        elsif client_name = options[:client]
          workflow.config.client(client_name)
        end
      end
    end

    module Registration
      def activity(activity_name, method_name)
        klass = self
        if klass.method_defined?(method_name)
          Handler.add(activity_name, klass, method_name)
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
