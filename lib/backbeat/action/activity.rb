module Backbeat
  module Action
    class Activity
      def self.build(name, klass, method, *args)
        new(name: name, class: klass, method: method, args: args)
      end

      def initialize(args)
        @args = args
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

      def contextible
        klass
      end

      def run(context)
        ret_val = nil
        contextible.with_context(context) do |contextible|
          context.processing
          ret_val = contextible.send(method, *args)
          context.complete
        end
        ret_val
      rescue => e
        context.errored
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
    end
  end
end
