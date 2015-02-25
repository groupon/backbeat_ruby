require "httparty"

module Backbeat
  class HttpClient
    def initialize(host, client_id)
      @host = host
      @client_id = client_id
    end

    def get(path, options = {})
    end

    def post(path, data, options = {})
    end

    def put(path, data, options = {})
    end
  end
end
