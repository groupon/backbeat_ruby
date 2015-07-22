require "httparty"

module Backbeat
  class Api
    class HttpClient
      def initialize(host, client_id)
        @host = host
        @client_id = client_id
      end

      def get(path, options = {})
        response = HTTParty.get(url(path), build_options(options))
        response_to_hash(response)
      end

      def post(path, data, options = {})
        response = HTTParty.post(url(path), build_options(options, data))
        response_to_hash(response)
      end

      def put(path, data, options = {})
        response = HTTParty.put(url(path), build_options(options, data))
        response_to_hash(response)
      end

      private

      attr_reader :host, :client_id

      def response_to_hash(response)
        {
          status: response.code,
          body: response.body,
          headers: response.headers
        }
      end

      def build_options(raw_options, data = nil)
        options = {}
        options = options.merge(headers: raw_options.fetch(:headers, {}).merge(authorization_header))
        options = options.merge(query: raw_options[:query]) if raw_options[:query]
        options = options.merge(body: data) if data
        options
      end

      def authorization_header
        {
          "AUTHORIZATION" => "Backbeat #{client_id}",
          "CLIENT-ID" => client_id
        }
      end

      def url(path)
        "http://#{host}#{path}"
      end
    end
  end
end
