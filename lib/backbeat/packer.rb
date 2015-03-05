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
      context_data = {
        workflow_id: data[:workflow_id],
        event_id: data[:id],
        subject: data[:subject],
        decider: data[:decider]
      }
      context = Backbeat.context.new(context_data, Backbeat.api)
      yield context if block_given?
      context
    end

    def self.unpack_action(data)
      action_data = data[:client_data][:action]
      action_data[:class] = Object.const_get(action_data[:class].to_s)
      action_data[:method] = action_data[:method].to_sym
      action_klass = Action.const_get(action_data[:type])
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
