require "backbeat"
require "backbeat/action/activity"
require "backbeat/action/findable_activity"

module Backbeat
  class Packer
    def self.unpack(data)
      context = unpack_context(data)
      action = unpack_action(data)
      yield context, action
    end

    def self.unpack_context(data)
      context = Backbeat.context.new({
        workflow_id: data[:workflow_id],
        event_id: data[:id],
        subject: data[:subject],
        decider: data[:decider]
      }, Backbeat.api)
      yield context if block_given?
      context
    end

    def self.unpack_action(data)
      action_type = data[:client_data][:action][:type]
      action_klass = Action.const_get(action_type)
      action_data = data[:client_data][:action]
      action_klass.new(action_data)
    end

    def self.pack_action(action, mode, fires_at = nil)
      action_hash = action.to_hash
      {
        name: action_hash[:name],
        mode: mode,
        fires_at: fires_at,
        client_data: {
          action: action_hash
        }
      }
    end
  end
end
