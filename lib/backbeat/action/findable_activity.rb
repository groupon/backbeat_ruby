require "backbeat/action"
require "backbeat/packer"

module Backbeat
  class Action
    class FindableActivity
      def self.build(name, object, method, args)
        new(name: name, class: object.class, id: object.id, method: method, args: args)
      end

      def initialize(args)
        @args = args
      end

      def run(workflow)
        Action.build(workflowable, method, args).run(workflow)
      end

      def to_hash
        {
          type: self.class.to_s,
          name: name,
          class: klass.to_s,
          id: id,
          method: method,
          args: args
        }
      end

      private

      def workflowable
        klass.find(id)
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
        @args[:method]
      end

      def args
        @args[:args]
      end
    end
  end
end
