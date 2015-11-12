# Copyright (c) 2015, Groupon, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# Neither the name of GROUPON nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "spec_helper"
require "backbeat"
require "backbeat/workflow"
require "backbeat/workflowable"
require "backbeat/activity"
require "backbeat/memory_store"

describe Backbeat::Workflow do

  let(:store) {
    Backbeat::MemoryStore.new(
      activities: {
        5 => {},
        6 => {}
      },
      workflows: {
        1 => { activities: [:activity_1, :activity_2, :activity_3] },
        2 => { complete: false }
      }
    )
  }

  context ".continue" do
    before do
      Backbeat.configure do |config|
        config.context = :remote
        config.store = store
      end
    end

    class MyArray
      include Backbeat::Workflowable

      def build(n)
        Array.new(n)
      end

      def size
        1
      end

      def step_two
        MyArray.in_context(workflow).size
      end

      def step_one
        MyArray.in_context(workflow).build(5)
        MyArray.in_context(workflow).step_two
      end
    end

    let(:activity_data) {
      {
        name: "Activity 1",
        client_data: {
          class_name: "MyArray",
          method: "build",
          params: [5]
        }
      }
    }

    it "continues the workflow from the workflow data" do
      workflow_data = activity_data.merge({ workflow_id: 1, id: 2 })

      workflow = Backbeat::Workflow.continue(workflow_data)

      expect(workflow.current_activity.result).to eq(Array.new(5))
    end

    it "handles workflow data returned as a decision" do
      activity_data[:client_data][:params] = [6]
      workflow_data = activity_data.merge({ workflow_id: 1, id: 2 })

      workflow = Backbeat::Workflow.continue({ "decision" => workflow_data })

      expect(workflow.current_activity.result).to eq(Array.new(6))
    end

    it "handles workflow data returned as an activity" do
      activity_data[:client_data][:params] = [7]
      workflow_data = activity_data.merge({ workflow_id: 1, id: 2 })

      workflow = Backbeat::Workflow.continue({ "activity" => workflow_data })

      expect(workflow.current_activity.result).to eq(Array.new(7))
    end
  end

  let(:config) {
    config = Backbeat::Config.new
    config.context = :remote
    config.store = store
    config
  }

  let(:activity_data) {
    {
      id: 6,
      name: "MyActivity",
      mode: "blocking",
      client_data: {
        class: MyArray,
        method: "size",
        params: []
      }
    }
  }

  let(:activity) {
    Backbeat::Activity.new({
      activity_data: activity_data,
      config: config
    })
  }

  let(:workflow) {
    Backbeat::Workflow.new({
      workflow_data: { id: 1, name: "MyWorkflow" },
      current_activity: activity,
      config: config
    })
  }

  context "#deactivate" do
    it "marks the current activity and previous activities as deactivated" do
      workflow.deactivate

      expect(store.find_activity_by_id(5)[:statuses].last).to eq(:deactivated)
      expect(store.find_activity_by_id(6)[:statuses].last).to eq(:deactivated)
    end
  end

  context "#activity_history" do
    it "returns the workflow activity history" do
      history = workflow.activity_history

      expect(history).to eq([:activity_1, :activity_2, :activity_3])
    end
  end

  context "#complete" do
    it "completes a workflow" do
      workflow.complete

      expect(store.find_workflow_by_id(1)[:complete]).to eq(true)
    end
  end

  context "#complete?" do
    it "returns false if the workflow is not complete" do
      expect(workflow.complete?).to eq(false)
    end

    it "returns true if the workflow is complete" do
      workflow.complete

      expect(workflow.complete?).to eq(true)
    end
  end

  context "#signal" do
    let(:new_activity) {
      Backbeat::Activity.new({
        activity_data: {
          name: "Hello",
          mode: "blocking",
          client_data: {
            class: MyArray,
            method: "size",
            params: []
          }
        },
        config: config
      })
    }

    it "creates a new workflow if one is not found" do
      workflow = Backbeat::Workflow.new({
        workflow_data: { subject: "new subject", name: "new workflow" },
        config: config
      })

      workflow.signal(new_activity)
      signal_data = new_activity.to_hash.merge({ id: 7 })

      expect(store.find_workflow_by_id(3)[:signals]["Hello"]).to eq(signal_data)
    end

    it "signals an activity to an existing workflow" do
      workflow.signal(new_activity)
      signal_data = new_activity.to_hash.merge({ id: 7 })

      expect(store.find_workflow_by_id(1)[:signals]["Hello"]).to eq(signal_data)
    end

    it "sets the id on the new activity" do
      workflow.signal(new_activity)

      expect(new_activity.id).to eq(7)
    end

    it "runs the activity if the context is local" do
      config.context = :local

      workflow.signal(new_activity)

      expect(store.find_activity_by_id(new_activity.id)[:statuses].last).to eq(:completed)
    end
  end

  context "#register" do
    let(:new_activity) {
      Backbeat::Activity.new({
        activity_data: {
          name: "MyNewActivity",
          mode: "blocking",
          client_data: {
            class: MyArray,
            method: "size",
            params: []
          }
        },
        config: config
      })
    }

    it "registers a child activity on the current activity" do
      workflow.register(new_activity)

      current_activity_id = workflow.current_activity.id
      registered_activity_id = store.find_activity_by_id(current_activity_id)[:child_activities].first
      activity_data = store.find_activity_by_id(registered_activity_id)

      expect(activity_data).to eq(new_activity.to_hash.merge({ id: 7 }))
    end

    it "runs the activity if the context is local" do
      config.context = :local

      workflow.register(new_activity)

      expect(store.find_activity_by_id(new_activity.id)[:statuses].last).to eq(:completed)
    end
  end

  context "#run" do
    require "support/mock_logger"

    it "logs if a logger is configured" do
      logger = Backbeat::MockLogger.new
      config.logger = logger

      workflow.run(activity)

      expect(logger.msgs[:info].count).to eq(2)
    end

    it "runs the activity with a workflow having the new activity as the current activity" do
      config.context = :local

      activity_data[:client_data][:method] = :step_one
      activity_data[:client_data][:params] = []

      workflow.run(activity)

      activity_record_1 = store.find_activity_by_id(activity.id)
      child_activities_1 = activity_record_1[:child_activities]

      expect(child_activities_1.count).to eq(2)

      activity_record_2 = store.find_activity_by_id(child_activities_1.last)
      child_activities_2 = activity_record_2[:child_activities]

      expect(child_activities_2.count).to eq(1)
    end
  end
end
