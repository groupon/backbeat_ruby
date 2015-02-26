module Backbeat
  class Packer
    def self.unpack_context(data)
    end

    def self.unpack_action(data)
    end

    def self.pack_context(context)
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
