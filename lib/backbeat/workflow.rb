require "backbeat/packer"

module Backbeat
  module Workflow
    def self.new(workflow_data)
      Packer.unpack_workflow(workflow_data)
    end

    def self.continue(workflow_data)
      workflow = Packer.unpack_workflow(workflow_data)
      action = Packer.unpack_action(workflow_data)
      action.run(workflow)
    end
  end
end
