require "backbeat/api/json_api_client"

module Backbeat
  class Api
    class Events
      def initialize(http_client)
        @http_client = JsonApiClient.new(http_client)
      end

      def find_event_by_id(id)
        http_client.get("/v2/events/#{id}")
      end

      def update_event_status(id, status)
        http_client.put("/v2/events/#{id}/status/#{status}", {})
      end

      def restart_event(id)
        http_client.put("/v2/events/#{id}/restart", {})
      end

      def add_child_events(id, data)
        http_client.post("/v2/events/#{id}/decisions", data)
      end

      private

      attr_reader :http_client
    end
  end
end
