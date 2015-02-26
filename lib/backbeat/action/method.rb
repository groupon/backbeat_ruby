module Backbeat
  module Action
    module Command
      def self.build(name, resource, method, *args)
        new(name: name, class: resource.class, id: resource.id, method: method, args: args)
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

      def id
        @args[:id]
      end

      def method
        :call
      end

      def args
        @args[:args]
      end

      def contextible
        klass.find(id)
      end

      def run(context)
        contextible.with_context(context) do |contextible|
          contexible.send(method, *args)
        end
      end

      def to_hash
        {
          type: "Method"
          name: name,
          class: klass,
          method: method,
          args: args
        }
      end
    end
  end
end
