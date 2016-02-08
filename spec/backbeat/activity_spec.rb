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
require "backbeat/activity"

describe Backbeat::Activity do

  class MyWorkflow

    def self.complete!
      @complete = true
    end

    def self.complete?
      @complete
    end

    def boom(*args)
      raise "Failed"
    end

    def perform(a, b, c)
      a + b + c
    end

    def finish
      MyWorkflow.complete!
    end
  end

  let(:store) {
    Backbeat::MemoryStore.new(
      activities: {
        10 => {},
        11 => {}
      },
      workflows: {
        1 => { activities: [:activity_1, :activity_2, :activity_3] },
        2 => { complete: false }
      }
    )
  }

  let(:config) {
    config = Backbeat::Config.new
    config.context = :remote
    config.store = store
    config
  }

  let(:now) { Time.now }

  let(:activity_data) {
    {
      id: 11,
      name: "MyActivity",
      mode: "blocking",
      fires_at: now,
      class: MyWorkflow,
      method: "perform",
      params: [1, 2, 3],
      client_data: {
        class_name: "MyWorkflow",
        method: "perform"
      }
    }
  }
  let(:activity) {
    Backbeat::Activity.new(activity_data.merge({ config: config }))
  }

  context "#run" do
    it "calls the method on the object with the arguments" do
      expect_any_instance_of(MyWorkflow).to receive(:perform).with(1, 2, 3)

      activity.run
    end

    it "sets the workflow context on the worflowable object" do
      activity_data[:method] = :finish
      activity_data[:params] = []

      activity.run

      expect(MyWorkflow.complete?).to eq(true)
    end

    it "sends a processing message to the activity" do
      activity.run

      activity_record = store.find_activity_by_id(activity.id)

      expect(activity_record[:statuses].first).to eq(:processing)
    end

    it "sends a complete message with the result to the workflow" do
      activity.run

      activity_record = store.find_activity_by_id(activity.id)

      expect(activity_record[:statuses].last).to eq(:complete)
      expect(activity.result).to eq(6)
    end

    it "sends an error message to the workflow on error" do
      activity_data[:method] = :boom

      activity.run

      activity_record = store.find_activity_by_id(activity.id)

      expect(activity_record[:statuses].last).to eq(:errored)
      expect(activity.error[:message]).to eq("Failed")
    end
  end

  context "#register_child" do
    let(:new_activity) {
      Backbeat::Activity.new({
        name: "SubActivity",
        mode: "blocking",
        class: MyWorkflow,
        method: "perform",
        params: [10, 10, 10],
        client_data: {
          class_name: "MyWorkflow",
          method: "perform"
        },
        config: config
      })
    }

    it "registers a child activity" do
      activity.register_child(new_activity)

      registered_activity_id = store.find_activity_by_id(activity.id)[:child_activities].first
      activity_data = store.find_activity_by_id(registered_activity_id)

      expect(activity_data).to eq(new_activity.to_hash.merge({ id: 12 }))
    end

    it "sets the id on the child activity" do
      activity.register_child(new_activity)

      expect(new_activity.id).to eq(12)
    end

    it "runs the activity if the context is set to local" do
      config.context = :local

      activity.register_child(new_activity)

      expect(new_activity.result).to eq(30)
    end
  end

  context "#to_hash" do
    it "returns the activity data required by the server" do
      expect(activity.to_hash).to eq(
        {
          name: "MyActivity",
          mode: "blocking",
          fires_at: now,
          parent_link_id: nil,
          client_id: nil,
          client_data: {
            class_name: "MyWorkflow",
            method: "perform",
            params: [1, 2, 3]
          }
        }
      )
    end
  end

  context "#complete?" do
    it "returns false if the activity is not complete" do
      expect(activity.complete?).to eq(false)
    end

    it "returns true if the activity is complete" do
      activity.run

      expect(activity.complete?).to eq(true)
    end

    it "returns false if the activity errored" do
      activity_data[:method] = :boom

      activity.run

      expect(activity.complete?).to eq(false)
    end
  end
end
