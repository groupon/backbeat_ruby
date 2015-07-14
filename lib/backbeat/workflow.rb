require "backbeat/packer"

module Backbeat
  module Workflow
    def self.continue(workflow_data)
      data = Packer.underscore_keys(workflow_data)
      data = data[:activity] || data[:decision] || data
      workflow = new(data)
      action = Packer.unpack_action(data)
      action.run(workflow)
    end

    def self.new(workflow_data)
      data = workflow_data.merge({
        workflow_type: workflow_data[:name],
        event_id: workflow_data[:id]
      })
      case Backbeat.config.context
      when :remote
        Workflow::Remote.new(data, Backbeat.config.api)
      when :local
        Workflow::Local.new(data, {})
      end
    end
  end
end
