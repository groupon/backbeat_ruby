require "backbeat/packer"
require "backbeat/activity/log_decorator"

module Backbeat
  class Workflow
    def self.continue(data)
      workflow = Packer.unpack_workflow(data)
      activity = workflow.current_activity
      workflow.run(activity)
    end

    attr_reader :current_activity, :config

    def initialize(options = {})
      @workflow_data = options[:workflow_data] || {}
      @current_activity = options[:current_activity]
      @config = options[:config] || Backbeat.config
    end

    def deactivate
      store.update_activity_status(current_activity.id, :deactivated)
    end

    def activity_history
      store.find_all_workflow_activities(id)
    end

    def complete?
      !!store.find_workflow_by_id(id)[:complete]
    end

    def complete
      store.complete_workflow(id)
    end

    def signal(activity)
      activity_data = activity.to_hash
      new_id = store.signal_workflow(id, activity_data[:name], activity_data)
      activity.id = new_id
      run(activity) if config.local?
    end

    def register(activity)
      current_activity.register_child(activity)
      run(activity) if config.local?
    end

    def id
      @id ||= (
        workflow_data[:id] || get_workflow_for_subject[:id]
      )
    end

    def run(activity)
      if logger = config.logger
        runner = Activity::LogDecorator.new(activity, logger)
      else
        runner = activity
      end
      runner.run(
        Workflow.new({
          workflow_data: workflow_data,
          current_activity: activity,
          config: config
        })
      )
    end

    private

    attr_reader :workflow_data

    def store
      config.store
    end

    def subject
      workflow_data[:subject] || {}
    end

    def get_workflow_for_subject
      subject_string = Packer.subject_to_string(subject)

      workflow_params = workflow_data.merge({ subject: subject_string })

      store.find_workflow_by_subject(workflow_params) ||
        store.create_workflow(workflow_params)
    end
  end
end
