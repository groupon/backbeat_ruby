require "backbeat/packer"

module Backbeat
  module Workflow
    def self.new(workflow_data)
      Packer.unpack_workflow(workflow_data)
    end

    def self.continue(workflow_data)
      data = Packer.underscore_keys(workflow_data)
      data = data[:activity] || data[:decision] || data
      workflow = Packer.unpack_workflow(data)
      action = Packer.unpack_action(data)
      action.run(workflow)
    end
  end
end
