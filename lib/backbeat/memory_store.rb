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
  class MemoryStore
    def initialize(seeds = {})
      @seeds = seeds
    end

    def create_workflow(data)
      last_id = workflows.keys.sort.last || 0
      new_id = last_id + 1
      workflow = {
        id: new_id,
        subject: data[:subject],
        name: (data[:name] || data[:workflow_type]).to_s
      }
      workflows[new_id] = workflow
      workflow
    end

    def find_workflow_by_id(id)
      workflows[id]
    end

    def find_workflow_by_subject(data)
      workflow = workflows.find do |id, workflow|
        data[:subject] == workflow[:subject]
      end
      workflow.last.merge(id: workflow.first) if workflow
    end

    def find_activity_by_id(id)
      activities[id]
    end

    def update_activity_status(activity_id, status, response = {})
      status = :complete if status == :completed # The server handles the completed event by marking status as complete
      activity = activities[activity_id] ||= {}
      statuses = activity[:statuses] ||= []
      statuses << status
      activity[:current_client_status] = status
      activity[:current_server_status] = status
      activity[:response] = response
      if status == :deactivated
        activities.each do |activity_id, activity_data|
          statuses = activity_data[:statuses] ||= []
          statuses << :deactivated
        end
      end
    end

    def get_activity_response(id)
      activities[id][:response] ||= {}
    end

    def find_all_workflow_activities(workflow_id)
      workflows[workflow_id][:activities]
    end

    def complete_workflow(workflow_id)
      workflow = workflows[workflow_id] ||= {}
      workflow[:complete] = true
    end

    def add_child_activity(activity_id, data)
      child_activity = data.merge(new_activity)
      activities[child_activity[:id]] = child_activity
      activity = activities[activity_id]
      activity[:child_activities] ||= []
      activity[:child_activities] << child_activity[:id]
      child_activity[:id]
    end

    def signal_workflow(id, name, data)
      child_activity = data.merge(new_activity)
      activities[child_activity[:id]] = child_activity
      workflows[id][:signals] ||= {}
      workflows[id][:signals][name] = child_activity
      child_activity[:id]
    end

    def find_all_workflow_children(id)
    end

    def get_workflow_tree(id)
    end

    def get_printable_workflow_tree(id)
    end

    def restart_activity(id)
    end

    def reset_activity(activity_id)
      activities[activity_id] ||= {}
      activities[activity_id][:reset] = true
    end

    def add_child_activities(id, data)
    end

    private

    attr_reader :seeds

    def new_activity
      { id: next_activity_id }
    end

    def next_activity_id
      last_id = activities.keys.sort.last || 0
      last_id + 1
    end

    def next_workflow_id
    end

    def activities
      seeds[:activities] ||= {}
      seeds[:activities]
    end

    def workflows
      seeds[:workflows] ||= {}
      seeds[:workflows]
    end
  end
end
