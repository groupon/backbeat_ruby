require "backbeat"
require "backbeat/api"
require "backbeat/api/http_client"
require "backbeat/context/remote/registry"

module Backbeat
  module Context
    class Remote
      def initialize(data, api = nil)
        @data = data
        @api = api || backbeat_api
      end

      def blocking(fires_at = nil)
        Registry.new(:blocking, fires_at, data, api)
      end

      def non_blocking(fires_at = nil)
        Registry.new(:non_blocking, fires_at, data, api)
      end

      def fire_and_forget(fires_at = nil)
        Registry.new(:fire_and_forget, fires_at, data, api)
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

      private

      attr_reader :api, :data

      def event_id
        data[:event_id]
      end

      def workflow_id
        data[:workflow_id]
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
