require "backbeat/api/json_api_client"

module Backbeat
  class Api
    class Activities
      def initialize(http_client)
        @http_client = JsonApiClient.new(http_client)
      end

      def find_activity_by_id(id)
        http_client.get("/v2/events/#{id}")
      end

      def update_activity_status(id, status, response = nil)
        http_client.put("/v2/events/#{id}/status/#{status}", { result: response })
      end

      def restart_activity(id)
        http_client.put("/v2/events/#{id}/restart", {})
      end

      def reset_activity(id)
        http_client.put("/v2/events/#{id}/reset", {})
      end

      def add_child_activities(id, data)
        http_client.post("/v2/events/#{id}/decisions", { decisions: data })
      end

      private

      attr_reader :http_client
    end
  end
end
