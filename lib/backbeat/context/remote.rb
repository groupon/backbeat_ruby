module Backbeat
  module Context
    class Remote
      def self.build(data)
        new(data, api)
      end

      def self.api
        @api ||= Api.new(HttpClient.new(
          Backbeat.config.host,
          Backbeat.config.client_id
        ))
      end

      def initialize(data, api)
        @data = data
        @api = api
      end

      def deciding
        api.update_event_status(event_id, :deciding)
      end

      def complete
        api.update_event_status(event_id, :complete)
      end

      def errored
        api.update_event_status(event_id, :errored)
      end

      def deactivate
        api.update_event_status(event_id, :deactivated)
      end

      def signal(signal_data)
        workflow_id = api.find_workflow_by_subject(signal_data)[:id]
        api.signal_workflow(workflow_id, signal_data)
      end

      def add_activity(activity_data)
        api.add_children_to_node(event_id, [activity_data])
      end

      def event_history
        api.find_all_workflow_events(workflow_id)
      end

      def complete_workflow!
        api.complete_workflow(dataworkflow_id)
      end
    end
  end
end
