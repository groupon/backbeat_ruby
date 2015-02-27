require "backbeat/api/json_api_client"

module Backbeat
  class Api
    class Workflows
      def initialize(http_client)
        @http_client = JsonApiClient.new(http_client)
      end

      def create_workflow(data)
        http_client.post("/v2/workflows", data)
      end

      def find_workflow_by_id(id)
        http_client.get("/v2/workflows/#{id}")
      end

      def find_workflow_by_subject(data)
        http_client.get("/v2/workflows", { query: data }, {
          404 => lambda { |response| false }
        })
      end

      def signal_workflow(id, name, data)
        http_client.post("/v2/workflows/#{id}/signal/#{name}", data)
      end

      def complete_workflow(id)
        http_client.put("/v2/workflows/#{id}/complete", {})
      end

      def find_all_children(id)
        http_client.get("/v2/workflows/#{id}/children")
      end

      def find_all_events(id)
        http_client.get("/v2/workflows/#{id}/events")
      end

      def get_tree(id)
        http_client.get("/v2/workflows/#{id}/tree")
      end

      def get_printable_tree(id)
        http_client.get("/v2/workflows/#{id}/tree/print")
      end

      private

      attr_reader :http_client
    end
  end
end
