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
require "securerandom"
require "backbeat/packer"

module Backbeat
  module Workflow
    class Local
      attr_reader :id

      def initialize(current_activity, state = {})
        @id = SecureRandom.uuid
        @current_activity = current_activity
        @state = state
        state[:activity_history] ||= []
        state[:activity_history] << current_activity
        Testing.activity_history = state[:activity_history]
      end

      def activity_processing
        add_activity_status(:processing)
      end

      def activity_completed(result)
        add_activity_status(:completed, { result: result })
      end

      def activity_errored(error)
        add_activity_status(:errored, { error: error.message })
      end

      def deactivate
        add_activity_status(:deactivated)
      end

      def activity_history
        state[:activity_history]
      end

      def complete?
        !!activity_history.find { |e| e[:name] == :workflow_complete }
      end

      def complete
        activity_history << { name: :workflow_complete }
      end

      def signal_workflow(activity, options)
        run_activity(activity, options.merge({ mode: :blocking }))
      end

      def run_activity(activity, options)
        activity_hash = activity.to_hash
        activity_name = activity_hash[:name]
        new_activity = current_activity.merge({
          id: SecureRandom.uuid,
          name: activity_name,
          activity: activity_hash,
          statuses: [],
        })
        activity_runner = jsonify_activity(activity, options)
        new_workflow = Local.new(new_activity, state)
        activity_runner.run(new_workflow) if Testing.run_activities?
        new_activity
      end

      def activity_id
        current_activity[:id]
      end

      private

      attr_reader :current_activity, :state

      def jsonify_activity(activity, options)
        Packer.unpack_activity(
          MultiJson.load(
            MultiJson.dump(Packer.pack_activity(activity, options)),
            symbolize_keys: true
          )
        )
      end

      def activity_name
        current_activity[:name]
      end

      def add_activity_status(status, response = nil)
        current_activity[:statuses] ||= []
        if status == :deactivated
          activity_history.each { |activity| activity[:statuses] << :deactivated }
        else
          current_activity[:statuses] << status
        end
        current_activity[:response] = response
      end
    end
  end
end
