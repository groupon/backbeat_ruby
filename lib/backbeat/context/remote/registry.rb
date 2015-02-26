require "backbeat/packer"

module Backbeat
  module Context
    class Remote
      class Registry
        attr_reader :mode, :fires_at

        def initialize(mode, fires_at, workflow_data, api)
          @mode = mode
          @fires_at = fires_at
          @workflow_data = workflow_data
          @api = api
        end

        def run(action)
          if signal?
            api.signal_workflow(workflow_id, action.name, event_data(action))
          else
            api.add_child_event(event_id, event_data(action))
          end
        end

        private

        attr_reader :workflow_data, :api

        def workflow_id
          @workflow_id ||= workflow_data[:workflow_id] || get_workflow_id
        end

        def get_workflow_id
          api.find_workflow_by_subject(workflow_data)[:id]
        end

        def event_id
          workflow_data[:event_id]
        end

        def signal?
          event_id.nil?
        end

        def event_data(action)
          Packer.pack_action(action, mode, fires_at)
        end
      end
    end
  end
end
