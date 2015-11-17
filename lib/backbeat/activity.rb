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

module Backbeat
  class Activity
    def initialize(options = {})
      @config  = options.delete(:config) || Backbeat.config
      @options = options
    end

    def run(workflow)
      object.with_context(workflow) do
        processing
        ret_value = object.send(method, *params)
        complete(ret_value)
      end
    rescue => e
      errored(e)
      raise e
    end

    def register_child(activity)
      new_id = store.add_child_activity(id, activity.to_hash)
      activity.id = new_id
      activity
    end

    def result
      store.get_activity_response(id)[:result]
    end

    def error
      store.get_activity_response(id)[:error]
    end

    def reset
      store.reset_activity(id)
    end

    def complete(ret_val)
      response = Packer.success_response(ret_val)
      store.update_activity_status(id, :completed, response)
    end

    def complete?
      store.find_activity_by_id(id)[:current_server_status] == :completed
    end

    def errored(error)
      response = Packer.error_response(error)
      store.update_activity_status(id, :errored, response)
    end

    def processing
      store.update_activity_status(id, :processing)
    end

    def to_hash
      options
    end

    def id
      options[:id]
    end

    def id=(new_id)
      options[:id] = new_id
    end

    def name
      options[:name]
    end

    def method
      client_data[:method]
    end

    def params
      client_data[:params]
    end

    private

    attr_reader :config, :options

    def store
      config.store
    end

    def client_data
      options[:client_data]
    end

    def object
      @object ||= (
        if id = client_data[:id]
          client_data[:class].find(id)
        else
          client_data[:class].new
        end
      )
    end
  end
end
