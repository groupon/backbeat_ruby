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

      def initialize(activity_data)
        @name = activity_data[:name]
        @klass = activity_data[:class]
        @id = activity_data[:id]
        @method = activity_data[:method]
        @params = activity_data[:params]
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
