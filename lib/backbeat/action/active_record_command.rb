module Backbeat
  module Action
    module ActiveRecordCommand
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
          type: "ActiveRecordCommand"
          name: name,
          class: klass,
          id: id,
          method: method,
          args: args
        }
      end
    end
  end
end
