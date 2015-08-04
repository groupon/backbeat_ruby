module Backbeat
  class MemoryApi
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
      activities[activity_id] ||= {}
      activities[activity_id][:status] = status
      activities[activity_id][:response] = response
      if status == :deactivated
        activities.each do |activity_id, activity_data|
          activity_data[:status] = :deactivated
        end
      end
    end

    def find_all_workflow_activities(workflow_id)
      workflows[workflow_id][:activities]
    end

    def complete_workflow(workflow_id)
      workflows[workflow_id] ||= {}
      workflows[workflow_id][:complete] = true
    end

    def add_child_activity(activity_id, data)
      child_activity = data.merge(new_activity)
      activities[child_activity[:id]] = child_activity
      activities[activity_id][:child_activities] ||= []
      activities[activity_id][:child_activities] << child_activity[:id]
    end

    def signal_workflow(id, name, data)
      child_activity = data.merge(new_activity)
      activities[child_activity[:id]] = child_activity
      workflows[id][:signals] ||= {}
      workflows[id][:signals][name] = child_activity
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
