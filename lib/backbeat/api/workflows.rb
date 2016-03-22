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

require "backbeat/api/json_api_client"

module Backbeat
  class API
    class Workflows
      def initialize(http_client)
        @http_client = JsonAPIClient.new(http_client)
      end

      def create_workflow(data)
        http_client.post("/workflows", data)
      end

      def find_workflow_by_id(id)
        http_client.get("/workflows/#{id}")
      end

      def find_workflow_by_subject(data)
        http_client.get("/workflows", { query: data }, {
          404 => lambda { |response| false }
        })
      end

      def signal_workflow(id, data)
        http_client.post("/workflows/#{id}/signal", data)
      end

      def complete_workflow(id)
        http_client.put("/workflows/#{id}/complete", {})
      end

      def find_all_children(id)
        http_client.get("/workflows/#{id}/children")
      end

      def find_all_activities(id)
        http_client.get("/workflows/#{id}/nodes")
      end

      def get_tree(id)
        http_client.get("/workflows/#{id}/tree")
      end

      def get_printable_tree(id)
        http_client.get("/workflows/#{id}/tree/print")
      end

      private

      attr_reader :http_client
    end
  end
end
