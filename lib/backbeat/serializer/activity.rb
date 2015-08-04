module Backbeat
  module Serializer
    class Activity
      def self.build(name, workflowable, method, params)
        new({
          name: name,
          class: workflowable,
          method: method,
          params: params
        })
      end

      attr_reader :name, :method, :params

      def initialize(action_data)
        @name = action_data[:name]
        @klass = action_data[:class]
        @method = action_data[:method]
        @params = action_data[:params]
      end

      def to_hash
        {
          serializer: self.class.to_s,
          name: name,
          class: klass.to_s,
          method: method,
          params: params
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
