module Backbeat
  class Activity
    def initialize(options = {})
      @activity_data = options[:activity_data] || {}
      @config = options[:config] || Backbeat.config
    end

    def run(workflow)
      object.with_context(workflow) do
        processing
        ret_value = object.send(method, *params)
        complete(ret_value)
      end
      workflow
    rescue => e
      errored(e)
      raise e
    end

    def register_child(activity)
      new_id = store.add_child_activity(id, activity.to_hash)
      activity.id = new_id
      activity
    end

    def result
      store.get_activity_response(id)[:result]
    end

    def error
      store.get_activity_response(id)[:error]
    end

    def reset
      store.reset_activity(id)
    end

    def complete(ret_val)
      response = Packer.success_response(ret_val)
      store.update_activity_status(id, :completed, response)
    end

    def errored(error)
      response = Packer.error_response(error)
      store.update_activity_status(id, :errored, response)
    end

    def processing
      store.update_activity_status(id, :processing)
    end

    def to_hash
      activity_data
    end

    def id
      activity_data[:id]
    end

    def id=(new_id)
      activity_data[:id] = new_id
    end

    def name
      activity_data[:name]
    end

    def params
      client_data[:params]
    end

    def method
      client_data[:method]
    end

    private

    def store
      config.store
    end

    def client_data
      activity_data[:client_data]
    end

    def object
      @object ||= (
        if id = client_data[:id]
          client_data[:class].find(id)
        else
          client_data[:class].new
        end
      )
    end

    attr_reader :activity_data, :config
  end
end
