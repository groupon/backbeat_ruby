class MemoryApi
  def initialize(seeds = {})
    @seeds = seeds
  end

  def events
    seeds[:events]
  end

  def workflows
    seeds[:workflows]
  end

  def find_workflow_by_id(id)
    workflows[id]
  end

  def find_workflow_by_subject(data)
    workflow = workflows.find do |id, workflow|
      data[:subject] == workflow[:subject]
    end
    workflow.last.merge(id: workflow.first)
  end

  def find_event_by_id(id)
    events[id]
  end

  def update_event_status(event_id, status)
    seeds[:events][event_id] ||= {}
    seeds[:events][event_id][:status] = status
  end

  def find_all_workflow_events(workflow_id)
    seeds[:workflows][workflow_id][:events]
  end

  def complete_workflow(workflow_id)
    seeds[:workflows][workflow_id][:complete] = true
  end

  def add_child_event(event_id, data)
    seeds[:events][event_id][:child_events] << data
  end

  def signal_workflow(id, name, data)
    seeds[:workflows][id][:signals][name] = data
  end

  private

  attr_reader :seeds
end
