require "backbeat/action"
require "backbeat/packer"

module Backbeat
  class Action
    class Activity
      def self.build(name, klass, method, args)
        new(name: name, class: klass, method: method, args: args)
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
          method: method,
          args: args
        }
      end

      private

      def workflowable
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
