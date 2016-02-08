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
require "backbeat/memory_store"
require "backbeat/workflow"
require "backbeat/workflowable"

describe Backbeat::Workflowable do

  class DoActivity
    include Backbeat::Workflowable

    def do_something(x, y)
      x + y
    end
  end

  class Decider
    include Backbeat::Workflowable

    def decision_one(a, b, c)
      DoActivity.in_context(workflow, :blocking).do_something(1, 2)
    end
  end

  let(:store) {
    Backbeat::MemoryStore.new({
      activities: { 1 => {} },
      workflows: { 5 => {} }
    })
  }
  let(:activity) {
    Backbeat::Activity.new({ id: 1 })
  }
  let(:workflow) {
    Backbeat::Workflow.new({
      id: 5,
      current_activity: activity
    })
  }
  let(:now) { Time.now }

  before do
    Backbeat.configure do |config|
      config.context = :remote
      config.store = store
    end
  end

  context ".in_context" do
    it "runs an activity in the set workflow" do
      Decider.in_context(workflow, :blocking, now).decision_one(:one, :two, :three)

      activity_id = store.find_activity_by_id(1)[:child_activities].first
      activity_data = store.find_activity_by_id(activity_id)

      expect(activity_data).to eq(
        {
          id: 2,
          name: "Decider#decision_one",
          mode: :blocking,
          fires_at: now,
          parent_link_id: nil,
          client_id: nil,
          client_data: {
            class_name: "Decider",
            method: :decision_one,
            params: [:one, :two, :three]
          }
        }
      )
    end

    it "sets the mode to blocking" do
      Decider.in_context(workflow).decision_one(:one, :two, :three)
      activity_id = store.find_activity_by_id(1)[:child_activities].first
      activity = store.find_activity_by_id(activity_id)

      expect(activity[:mode]).to eq(:blocking)
    end

    it "sets the mode to non_blocking" do
      Decider.in_context(workflow, :non_blocking).decision_one(:one, :two, :three)
      activity_id = store.find_activity_by_id(1)[:child_activities].first
      activity = store.find_activity_by_id(activity_id)

      expect(activity[:mode]).to eq(:non_blocking)
    end

    it "sets the mode to fire_and_forget" do
      Decider.in_context(workflow, :fire_and_forget).decision_one(:one, :two, :three)
      activity_id = store.find_activity_by_id(1)[:child_activities].first
      activity = store.find_activity_by_id(activity_id)

      expect(activity[:mode]).to eq(:fire_and_forget)
    end

    it "signals the workflow with an activity" do
      Decider.in_context(workflow, :signal).decision_one(:one, :two, :three)
      signal = store.find_workflow_by_id(5)[:signals]["Decider#decision_one"]

      expect(signal[:name]).to eq("Decider#decision_one")
      expect(signal[:mode]).to eq(:signal)
    end

    it "returns the activity" do
      Backbeat.local do |workflow|
        activity = DoActivity.in_context(workflow, :signal).do_something(3, 4)

        expect(activity.result).to eq(7)
      end
    end

    it "defaults to a local workflow" do
      Decider.new.decision_one(1, 2, 3)
    end
  end

  context ".start_context" do
    it "runs the activity on a new workflow for the subject" do
      subject = { id: 1, class: Array }

      Decider.start_context(subject).decision_one(:one, :two, :three)

      workflow = store.find_workflow_by_subject({ subject: subject.to_json })
      expect(workflow[:id]).to eq(6)
      expect(workflow[:name]).to eq("Decider")
      expect(workflow[:subject]).to eq(subject.to_json)
      expect(workflow[:signals].count).to eq(1)
    end
  end

  context ".link_context" do
    it "creates a signal activity with the current node linked" do
      subject = { id: 1, class: Array }

      Decider.link_context(workflow, subject).decision_one(:a, :b, :c)

      other_workflow = store.find_workflow_by_id(6)
      signal = other_workflow[:signals]["Decider#decision_one"]

      expect(other_workflow[:subject]).to eq(subject.to_json)
      expect(signal[:parent_link_id]).to eq(activity.id)
    end
  end
end
