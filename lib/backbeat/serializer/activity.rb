module Backbeat
  module Serializer
    class Activity
      def self.build(name, workflowable, method, args)
        new({
          name: name,
          class: workflowable,
          method: method,
          args: args
        })
      end

      attr_reader :name, :method, :args

      def initialize(action_data)
        @name = action_data[:name]
        @klass = action_data[:class]
        @method = action_data[:method]
        @args = action_data[:args]
      end

      def to_hash
        {
          serializer: self.class.to_s,
          name: name,
          class: klass.to_s,
          method: method,
          args: args
        }
      end

      def workflowable
        klass.new
      end

      private

      attr_reader :klass
    end
  end
end
