require "backbeat/api/json_api_client"

module Backbeat
  class Api
    class Events
      def initialize(http_client)
        @http_client = JsonApiClient.new(http_client)
      end

      def find_event_by_id(id)
        # get events/:id
      end

      def update_event_status(id, status)
        # put events/:id/status/:new_status
      end

      def restart_event(id)
        # put :id/restart
      end

      def add_children(id, data)
        # post :id/decisions
      end
    end
  end
end
