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

require "backbeat/packer"

module Backbeat
  module Workflow
    class Remote
      attr_reader :id

      def initialize(current_activity, api)
        @current_activity = current_activity
        @api = api
        @id = current_activity[:workflow_id] || get_workflow_for_subject[:id]
      end

      def activity_processing
        api.update_activity_status(activity_id, :processing)
      end

      def activity_completed(result)
        response = Packer.success_response(result)
        api.update_activity_status(activity_id, :completed, response)
      end

      def activity_errored(error)
        response = Packer.error_response(error)
        api.update_activity_status(activity_id, :errored, response)
      end

      def deactivate
        api.update_activity_status(activity_id, :deactivated)
      end

      def activity_history
        api.find_all_workflow_activities(id)
      end

      def complete?
        api.find_workflow_by_id(id)[:complete]
      end

      def complete
        api.complete_workflow(id)
      end

      def signal_workflow(activity, options = {})
        activity_data = Packer.pack_activity(activity, options.merge({ mode: :blocking }))
        api.signal_workflow(id, activity_data[:name], activity_data)
      end

      def run_activity(activity, options)
        activity_data = Packer.pack_activity(activity, options)
        api.add_child_activity(activity_id, activity_data)
      end

      def reset_activity
        api.reset_activity(activity_id)
      end

      def activity_id
        current_activity[:id] || workflow_error("No activity id present in current workflow data")
      end

      private

      attr_reader :api, :current_activity

      def get_workflow_for_subject
        workflow_data = current_activity.merge({
          subject: Packer.subject_to_string(current_activity[:subject])
        })
        api.find_workflow_by_subject(workflow_data) || api.create_workflow(workflow_data)
      end

      class WorkflowError < StandardError; end

      def workflow_error(message)
        raise WorkflowError.new(message)
      end
    end
  end
end
