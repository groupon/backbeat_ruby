class MemoryApi
  attr_reader :seeds

  def initialize(seeds)
    @seeds = seeds
  end

  def events
    seeds[:events]
  end

  def workflows
    seeds[:workflows]
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
    seeds[:workflows][workflow_id][:signals][name] = data
  end
end
