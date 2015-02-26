module Backbeat
  module Action
    module Command
      def self.build(name, klass, *args)
        new(name: name, class: klass, args: args)
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
        :call
      end

      def args
        @args[:args]
      end

      def contextible
        klass.new
      end

      def run(context)
        contextible.with_context(context) do |contextible|
          contexible.send(method, *args)
        end
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
    end
  end
end
