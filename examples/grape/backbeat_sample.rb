require 'grape'
require 'backbeat'

Backbeat.configure do |config|
  config.host      = "http://192.168.59.103:9292"
  config.client_id = "9ab09c2f-68d5-4e0e-8844-3637eea44254"
  config.context   = :remote
end

module BackbeatSample
  Logger = Logger.new(STDOUT)

  class BackbeatModel
    class AddSomething
      include Backbeat::Workflowable

      def add_2(x, y, total)
        new_total = total + x + y
        Logger.info "Output #{new_total}"
        sleep 10
      end

      def add_3(x, y, z, total)
        new_total = total + x + y + z
        Logger.info "Output #{new_total}"
        Logger.info "Registering more acitvities"
        sleep 10
        AddSomething.in_context(workflow, :blocking).add_2(5, 5, new_total)
        AddSomething.in_context(workflow, :fire_and_forget).add_2(1, 2, new_total)
      end
    end

    def self.signal_workflow
      # The following creates a workflow node with "a subject", and then starts the workflow with a signal
      subject = { id: 1, name: "AdditionJob" }
      BackbeatModel::AddSomething.start_context(subject).add_3(1, 2, 3, 50)
    end
  end

  class API < Grape::API
    format :json
    prefix :api

    post :activity do
      Logger.info "Running an activity."
      Logger.info params

      Backbeat::Workflow.continue(params)
    end

    post :notification do
      Logger.info params[:error]
    end
  end
end
