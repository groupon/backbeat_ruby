require "backbeat"
require "backbeat/actors/activity"
require "backbeat/actors/active_record_activity"

module Backbeat
  class Packer
    def self.unpack_context(data)
      Backbeat.context.new({
        workflow_id: data[:workflow_id],
        event_id: data[:event_id],
        subject: data[:subject],
        decider: data[:decider]
      })
    end

    def self.unpack_action(data)
      actor_type = data[:client_data][:action][:type]
      actor_klass = Actors.const_get(actor_type)
      actor_data = data[:client_data][:action]
      actor_data.delete(:type)
      actor_klass.new(actor_data)
    end

    def self.pack_action(action, mode, fires_at = nil)
      {
        name: action.name,
        mode: mode,
        fires_at: fires_at,
        client_data: {
          action: action.to_hash
        }
      }
    end
  end
end
