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

require "backbeat/activity"
require "backbeat/workflow"
require "active_support/inflector"

module Backbeat
  class Packer
    def self.unpack_activity(data)
      data = underscore_keys(data)
      data = data[:decision] || data[:activity] || data
      client_data = data[:client_data]
      klass = Inflector.constantize(client_data[:class_name] || client_data[:class])
      new_client_data = client_data.merge({ class: klass })
      activity_data = data.merge({ client_data: new_client_data })
      Activity.new(activity_data)
    end

    def self.unpack_workflow(data)
      activity = unpack_activity(data)
      Workflow.new({
        id: data[:workflow_id],
        subject: data[:subject],
        decider: data[:decider],
        name: data[:workflow_name],
        current_activity: activity
      })
    end

    def self.success_response(result)
      rpc_response({ result: result })
    end

    GENERIC_RPC_ERROR_CODE = -32000

    def self.error_response(error)
      rpc_response({
        error: {
          code: GENERIC_RPC_ERROR_CODE,
          message: error.message,
          data: (error.backtrace.take(5) if error.backtrace)
        }
      })
    end

    def self.rpc_response(params)
      {
        jsonrpc: "2.0",
        result: nil,
        error: nil,
        id: nil
      }.merge(params)
    end

    def self.subject_to_string(subject)
      case
      when subject.is_a?(String)
        subject
      when subject.is_a?(Hash)
        subject.to_json
      when subject.respond_to?(:id)
        { id: subject.id, class: subject.class }.to_json
      when subject.respond_to?(:to_hash)
        subject.to_hash.to_json
      else
        subject.to_json
      end
    end

    def self.underscore_keys(data)
      case data
      when Array
        data.map { |v| underscore_keys(v) }
      when Hash
        underscored_data = data.map do |(k, v)|
          [Inflector.underscore(k.to_s).to_sym, underscore_keys(v)]
        end
        Hash[underscored_data]
      else
        data
      end
    end

    class Inflector
      extend ActiveSupport::Inflector
    end
  end
end
