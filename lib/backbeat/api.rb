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

require "backbeat/api/workflows"
require "backbeat/api/activities"

module Backbeat
  class Api
    def initialize(http_client)
      @http_client = http_client
    end

    def create_workflow(data)
      workflows_api.create_workflow(data)
    end

    def find_workflow_by_id(id)
      workflows_api.find_workflow_by_id(id)
    end

    def find_workflow_by_subject(data)
      workflows_api.find_workflow_by_subject(data)
    end

    def signal_workflow(id, name, data)
      workflows_api.signal_workflow(id, name, data)
    end

    def complete_workflow(id)
      workflows_api.complete_workflow(id)
    end

    def find_all_workflow_children(id)
      workflows_api.find_all_children(id)
    end

    def find_all_workflow_activities(id)
      workflows_api.find_all_activities(id)
    end

    def get_workflow_tree(id)
      workflows_api.get_tree(id)
    end

    def get_printable_workflow_tree(id)
      workflows_api.get_printable_tree(id)
    end

    def find_activity_by_id(id)
      activities_api.find_activity_by_id(id)
    end

    def update_activity_status(id, status, result = nil)
      activities_api.update_activity_status(id, status, result)
    end

    def restart_activity(id)
      activities_api.restart_activity(id)
    end

    def reset_activity(id)
      activities_api.reset_activity(id)
    end

    def add_child_activity(id, data)
      add_child_activities(id, [data])
    end

    def add_child_activities(id, data)
      activities_api.add_child_activities(id, data)
    end

    private

    def workflows_api
      @workflows_api ||= Workflows.new(@http_client)
    end

    def activities_api
      @activities_api ||= Activities.new(@http_client)
    end
  end
end
