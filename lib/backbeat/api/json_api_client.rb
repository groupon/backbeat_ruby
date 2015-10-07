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

require "multi_json"
require "backbeat/api/errors"
require "backbeat/packer"

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
        if response[:body]
          Packer.underscore_keys(
            MultiJson.load(response[:body], symbolize_keys: true)
          )
        end
      rescue MultiJson::ParseError
        response[:body]
      end

      def handle_response(response, handlers)
        status = response[:status]
        if handler = handlers[status]
          handler.call(response)
        else
          case status
          when 200, 201
            parse_body(response)
          when 400, 422
            raise ValidationError, parse_body(response)
          when 401
            raise AuthenticationError, parse_body(response)
          when 404
            raise NotFoundError, parse_body(response)
          when 409
            raise InvalidStatusChangeError, parse_body(response)
          else
            raise ApiError, parse_body(response)
          end
        end
      end
    end
  end
end
