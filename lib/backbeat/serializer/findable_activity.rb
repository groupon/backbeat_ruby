module Backbeat
  module Serializer
    class FindableActivity
      def self.build(name, workflowable, method, params)
        new({
          name: name,
          class: workflowable.class,
          id: workflowable.id,
          method: method,
          params: params
        })
      end

      attr_reader :name, :method, :params

      def initialize(action_data)
        @name = action_data[:name]
        @klass = action_data[:class]
        @id = action_data[:id]
        @method = action_data[:method]
        @params = action_data[:params]
      end

      def to_hash
        {
          serializer: self.class.to_s,
          name: name,
          class: klass.to_s,
          id: id,
          method: method,
          params: params
        }
      end

      def workflowable
        klass.find(id)
      end

      private

      attr_reader :klass, :id
    end
  end
end
