require "backbeat/packer"
require "backbeat/workflow/local"
require "backbeat/workflow/remote"

module Backbeat
  module Workflow
    def self.continue(workflow_data)
      data = Packer.underscore_keys(workflow_data)
      data = data[:activity] || data[:decision] || data
      workflow = new(data)
      activity = Packer.unpack_activity(data)
      activity.run(workflow)
    end

    def self.new(workflow_data)
      data = workflow_data.merge({ workflow_type: workflow_data[:name] })
      case Backbeat.config.context
      when :remote
        Workflow::Remote.new(data, Backbeat.config.api)
      when :local
        Workflow::Local.new(data, {})
      end
    end
  end
end
