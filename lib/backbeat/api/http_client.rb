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

require "httparty"

module Backbeat
  class API
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
