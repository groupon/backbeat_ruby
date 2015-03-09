require "backbeat/action"

module Backbeat
  class Action
    class Activity
      def self.build(name, klass, method, args)
        new(name: name, class: klass, method: method, args: args)
      end

      def initialize(args)
        @args = args
      end

      def run(context)
        Action.new(contextible, method, args).run(context)
      end

      def to_hash
        {
          type: "Activity",
          name: name,
          class: klass,
          method: method,
          args: args
        }
      end

      private

      def contextible
        klass.new
      end

      def name
        @args[:name]
      end

      def klass
        @args[:class]
      end

      def method
        @args[:method]
      end

      def args
        @args[:args]
      end
    end
  end
end
