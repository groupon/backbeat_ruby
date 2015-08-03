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
