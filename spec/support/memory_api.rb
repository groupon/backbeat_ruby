module Backbeat
  class MemoryApi
    def initialize(seeds = {})
      @seeds = seeds
    end

    def create_workflow(data)
      last_id = workflows.keys.sort.last || 0
      id = last_id + 1
      workflow = { signals: {}, subject: data[:subject] }
      workflows[id] = workflow
      workflow.merge(id: id)
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

    def find_event_by_id(id)
      events[id]
    end

    def update_event_status(event_id, status)
      events[event_id] ||= {}
      events[event_id][:status] = status
    end

    def find_all_workflow_events(workflow_id)
      workflows[workflow_id][:events]
    end

    def complete_workflow(workflow_id)
      workflows[workflow_id][:complete] = true
    end

    def add_child_event(event_id, data)
      events[event_id] ||= { child_events: [] }
      events[event_id][:child_events] << data
    end

    def signal_workflow(id, name, data)
      workflows[id] ||= { signals: {} }
      workflows[id][:signals][name] = data
    end

    def find_all_workflow_children(id)
    end

    def get_workflow_tree(id)
    end

    def get_printable_workflow_tree(id)
    end

    def restart_event(id)
    end

    def add_child_events(id, data)
    end

    private

    attr_reader :seeds

    def events
      seeds[:events] ||= {}
      seeds[:events]
    end

    def workflows
      seeds[:workflows] ||= {}
      seeds[:workflows]
    end
  end
end
