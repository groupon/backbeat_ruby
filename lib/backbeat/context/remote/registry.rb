module Backbeat
  module Context
    class Remote
      class Registry
        attr_reader :mode, :fires_at

        def initialize(mode, fires_at, data, api)
          @mode = mode
          @fires_at = fires_at
          @data = data
          @api = api
        end

        def run(action)
          api.add_child_event(data[:event_id], {
            mode: mode,
            fires_at: fires_at,
            client_data: {
              action: action.to_hash
            }
          })
        end

        def determine_action
          # If no workflow_id
          #   find workflow by subject/decider
          #   signal workflow
          # If event_id and event_id != workflow_id
          #   add_node to event
          # Else
          #   find_workflow by workflow_id
          #   signal workflow
        end
      end
    end
  end
end
