require "backbeat/api/workflows"
require "backbeat/api/events"

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

    def find_all_workflow_events(id)
      workflows_api.find_all_events(id)
    end

    def get_workflow_tree(id)
      workflows_api.get_tree(id)
    end

    def get_printable_workflow_tree(id)
      workflows_api.get_printable_tree(id)
    end

    def find_event_by_id(id)
      events_api.find_event_by_id(id)
    end

    def update_event_status(id, status)
      events_api.update_event_status(id, status)
    end

    def restart_event(id)
      events_api.restart_event(id)
    end

    def add_child_event(id, data)
      add_child_events(id, [data])
    end

    def add_child_events(id, data)
      events_api.add_child_events(id, { args: { decisions: data }})
    end

    private

    def workflows_api
      @workflows_api ||= Workflows.new(@http_client)
    end

    def events_api
      @events_api ||= Events.new(@http_client)
    end
  end
end
