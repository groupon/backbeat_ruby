module Backbeat
  class MemoryApi
    def initialize(seeds = {})
      @seeds = seeds
    end

    def create_workflow(data)
      last_id = workflows.keys.sort.last || 0
      new_id = last_id + 1
      workflow = { id: new_id, subject: data[:subject] }
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
      workflows[workflow_id] ||= {}
      workflows[workflow_id][:complete] = true
    end

    def add_child_event(event_id, data)
      child_event = data.merge(new_event)
      events[child_event[:id]] = child_event
      events[event_id][:child_events] ||= []
      events[event_id][:child_events] << child_event[:id]
    end

    def signal_workflow(id, name, data)
      child_event = data.merge(new_event)
      events[child_event[:id]] = child_event
      workflows[id][:signals] ||= {}
      workflows[id][:signals][name] = child_event
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

    def new_event
      { id: next_event_id }
    end

    def next_event_id
      last_id = events.keys.sort.last || 0
      last_id + 1
    end

    def next_workflow_id
    end

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
