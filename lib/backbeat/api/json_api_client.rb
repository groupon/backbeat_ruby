require "multi_json"
require "backbeat/api/errors"

module Backbeat
  class Api
    class JsonApiClient
      def initialize(http_client)
        @http_client = http_client
      end

      def get(path, query = {}, handlers = {})
        response = http_client.get(path, {
          headers: { "Accept" => "application/json"}
        }.merge(query))
        handle_response(response, handlers)
      end

      def post(path, data, handlers = {})
        response = http_client.post(path, MultiJson.dump(data), {
          headers: {
            "Accept" => "application/json",
            "Content-Type" => "application/json"
          }
        })
        handle_response(response, handlers)
      end

      def put(path, data, handlers = {})
        response = http_client.put(path, MultiJson.dump(data), {
          headers: {
            "Accept" => "application/json",
            "Content-Type" => "application/json"
          }
        })
        handle_response(response, handlers)
      end

      private

      attr_reader :http_client

      def parse_body(response)
        MultiJson.load(response[:body], symbolize_keys: true) if response[:body]
      end

      def handle_response(response, handlers)
        if handler = handlers[response[:status]]
          handler.call(response)
        else
          case response[:status]
          when 200
            parse_body(response)
          when 201
            parse_body(response)
          when 404
            raise NotFoundError
          when 422
            raise ValidationError
          end
        end
      end
    end
  end
end
