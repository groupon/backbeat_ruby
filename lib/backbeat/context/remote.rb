require "backbeat"
require "backbeat/api"
require "backbeat/api/http_client"
require "backbeat/packer"

module Backbeat
  module Context
    class Remote
      def initialize(data, api = nil)
        @data = data
        @api = api || backbeat_api
      end

      def processing
        api.update_event_status(event_id, :processing)
      end

      def complete
        api.update_event_status(event_id, :complete)
      end

      def errored
        api.update_event_status(event_id, :errored)
      end

      def event_history
        api.find_all_workflow_events(data[:workflow_id])
      end

      def complete_workflow!
        api.complete_workflow(workflow_id)
      end

      def run_activity(action, mode, fires_at = nil)
        event_data = build_event_data(action, mode, fires_at)
        if signal?
          api.signal_workflow(workflow_id, action.name, event_data)
        else
          api.add_child_event(event_id, event_data)
        end
      end

      private

      attr_reader :api, :data

      def event_id
        data[:event_id]
      end

      def workflow_id
        @workflow_id ||= data[:workflow_id] || get_workflow[:id]
      end

      def get_workflow
        api.find_workflow_by_subject(data) ||
          api.create_workflow(data)
      end

      def signal?
        event_id.nil?
      end

      def build_event_data(action, mode, fires_at)
        Packer.pack_action(action, mode, fires_at)
      end

      def backbeat_api
        Api.new(Api::HttpClient.new(
          Backbeat.config.host,
          Backbeat.config.client_id
        ))
      end
    end
  end
end
