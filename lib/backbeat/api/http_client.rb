# Copyright (c) 2015, Groupon, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# Neither the name of GROUPON nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "net/http"

module Backbeat
  class API
    class HttpClient
      def initialize(host, client_id, auth_token, port = 80)
        @host = host
        @client_id = client_id
        @auth_token = auth_token
        @port = port
      end

      def get(path, options = {})
        make_request(Net::HTTP::Get, path, build_options(options))
      end

      def post(path, data, options = {})
        make_request(Net::HTTP::Post, path, build_options(options, data))
      end

      def put(path, data, options = {})
        make_request(Net::HTTP::Put, path, build_options(options, data))
      end

      private

      attr_reader :host, :port, :client_id, :auth_token

      def build_options(raw_options, data = nil)
        options = {}
        options = options.merge(headers: raw_options.fetch(:headers, {}).merge(authorization_header))
        options = options.merge(query: raw_options[:query]) if raw_options[:query]
        options = options.merge(body: data) if data
        options
      end

      AUTHORIZATION = 'Authorization'.freeze
      CLIENT_ID = 'Client-Id'.freeze

      def authorization_header
        {
          AUTHORIZATION => "Token token=\"#{auth_token}\"",
          CLIENT_ID => client_id
        }
      end

      def make_request(klass, path, options)
        uri = build_uri(path, options[:query])
        req = klass.new(uri)
        options[:headers].each { |header, value| req[header] = value }
        req.body = options[:body] if options[:body]
        response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
        response_to_hash(response)
      end

      def build_uri(path, query)
        uri = URI("http://#{host}:#{port}#{path}")
        if query
          uri.query = URI.encode_www_form(query)
        end
        uri
      end

      def response_to_hash(response)
        headers = {}
        response.each_header { |k, v| headers[k] = v }
        {
          status: response.code.to_i,
          body: response.body,
          headers: headers
        }
      end
    end
  end
end
