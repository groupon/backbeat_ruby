require "backbeat/action"

module Backbeat
  module Actors
    class Command
      def self.build(name, klass, *args)
        new(name: name, class: klass, args: args)
      end

      def initialize(args)
        @args = args
      end

      def name
        @args[:name]
      end

      def run(context)
        Action.new(contextible, method, args).run(context)
      end

      def to_hash
        {
          type: "Command",
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

      def klass
        @args[:class]
      end

      def method
        :call
      end

      def args
        @args[:args]
      end
    end
  end
end
