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
require "backbeat/handler"
require "backbeat"

describe Backbeat::Handler do

  class Cooking
    include Backbeat::Handler

    class << self
      attr_accessor :rescued
    end

    def chop(amount)
      register("cooking-workflow.activity-2").with(10)
      amount * 2
    end
    activity "cooking-workflow.activity-1", :chop, { rescue_with: :cleanup }

    def cleanup(activity)
      Backbeat.register("cooking-workflow.last-activity").call
      activity.resolve
      Cooking.rescued = true
    end

    def fry(a, b)
      register("cooking-workflow.last-activity").call
      (a + b) * 3
    end
    activity "cooking-workflow.activity-2", :fry, { backoff: 10 }

    def serve
      :done
    end
    activity "cooking-workflow.last-activity", :serve

    def order_wine(n)
    end
    activity "cooking-workflow.async-activity", :order_wine, { async: true }
  end

  let(:handlers) { Backbeat::Handler.__handlers__ }

  let(:store) { Backbeat::MemoryStore.new }

  before do
    Backbeat.configure do |config|
      config.context = :remote
      config.store = store
    end
  end

  it "registers activities" do
    expect(handlers["cooking-workflow.activity-1"]).to eq({
      class: Cooking,
      method: :chop,
      options: {
        rescue_with: :cleanup
      }
    })
    expect(handlers["cooking-workflow.async-activity"][:options]).to eq({ async: true })
  end

  it "raises an exception if the method does not exist" do
    expect {
      Cooking.activity("name", :foo)
    }.to raise_error(Backbeat::Handler::ActivityRegistrationError, "Method foo does not exist")
  end

  context "#signal" do
    it "signals a workflow with the activity" do
      activity = Backbeat::Handler.signal("cooking-workflow.activity-1", "new subject").with(5)

      activity.run
      activity_data = store.find_workflow_by_id(1)[:signals]["cooking-workflow.activity-1"]

      expect(activity_data[:name]).to eq("cooking-workflow.activity-1")
      expect(activity_data[:mode]).to eq(:blocking)
      expect(activity_data[:client_data]).to eq({
        name: "cooking-workflow.activity-1",
        params: [5]
      })
      expect(activity.result).to eq(10)
    end

    it "handles the fires_at option for the signal" do
      tomorrow = Time.now + 60 * 60 * 24
      activity = Backbeat::Handler.signal(
        "cooking-workflow.activity-1",
        "new subject",
        { fires_at: tomorrow }
      ).with(5)

      activity_data = store.find_workflow_by_id(1)[:signals]["cooking-workflow.activity-1"]

      expect(activity_data[:fires_at]).to eq(tomorrow)
    end

    it "handles the client_id option for the signal" do
      activity = Backbeat::Handler.signal(
        "cooking-workflow.other-activity",
        "new subject",
        { client_id: "123" }
      ).with(5)

      activity_data = store.find_workflow_by_id(1)[:signals]["cooking-workflow.other-activity"]

      expect(activity_data[:client_id]).to eq("123")
    end

    it "handles the client option mapped to a client_id" do
      Backbeat.config.client(:shipping, '123')

      activity = Backbeat::Handler.signal(
        "cooking-workflow.other-activity",
        "new subject",
        { client: :shipping }
      ).with(5)

      activity_data = store.find_workflow_by_id(1)[:signals]["cooking-workflow.other-activity"]

      expect(activity_data[:client_id]).to eq("123")
    end

    it "adds the backoff option defined in the registration of the activity" do
      activity = Backbeat::Handler.signal(
        "cooking-workflow.activity-2",
        "new subject"
      ).with(5)

      activity_data = store.find_activity_by_id(activity.id)

      expect(activity_data[:retry_interval]).to eq(10)
    end

    it "uses a provided workflow name" do
      activity = Backbeat::Handler.signal(
        "cooking-workflow.async-activity",
        "new subject",
        { name: "Test Workflow" }
      ).with(5)

      workflow_data = store.find_workflow_by_id(1)

      expect(workflow_data[:name]).to eq("Test Workflow")
    end

    it "raises an exception if the activity name is not found" do
      expect {
        Backbeat::Handler.signal("cooking-workflow.wrong-activity", "subject").with(10)
      }.to raise_error(Backbeat::Handler::ActivityNotFoundError)
    end

    it "does not raise an exception for activities on other clients" do
      expect {
        Backbeat::Handler.signal("cooking-workflow.wrong-activity", "subject", { client_id: "123" }).with(10)
      }.to_not raise_error
    end
  end

  context "#register" do
    let(:parent_activity) {
      Cooking.new.signal("cooking-workflow.activity-1", "new subject").with(5)
    }

    it "registers an activity in an existing workflow" do
      activity = Backbeat::Handler.with_current_activity(parent_activity) do
        Backbeat::Handler.register("cooking-workflow.activity-2", mode: :non_blocking).with(1, 2)
      end

      activity.run
      activity_data = store.find_activity_by_id(activity.id)

      expect(activity_data[:name]).to eq("cooking-workflow.activity-2")
      expect(activity_data[:mode]).to eq(:non_blocking)
      expect(activity_data[:client_data]).to eq({
        name: "cooking-workflow.activity-2",
        params: [1, 2]
      })
      expect(activity.result).to eq(9)
    end

    it "handles the client_id option" do
      activity = Backbeat::Handler.with_current_activity(parent_activity) do
        Backbeat::Handler.register("cooking-workflow.activity-12", client_id: 'abc').with(1, 2)
      end

      activity_data = store.find_activity_by_id(activity.id)

      expect(activity_data[:client_id]).to eq('abc')
    end

    it "handles the client option" do
      Backbeat.config.client(:shipping, 'abc')

      activity = Backbeat::Handler.with_current_activity(parent_activity) do
        Backbeat::Handler.register("cooking-workflow.activity-12", client: :shipping).with(1, 2)
      end

      activity_data = store.find_activity_by_id(activity.id)

      expect(activity_data[:client_id]).to eq('abc')
    end

    it "handles the fires_at option" do
      today = Time.now

      activity = Backbeat::Handler.with_current_activity(parent_activity) do
        Backbeat::Handler.register("cooking-workflow.activity-2", fires_at: today).with(1, 2)
      end

      activity_data = store.find_activity_by_id(activity.id)

      expect(activity_data[:fires_at]).to eq(today)
    end

    it "adds the backoff option defined in the registration of the activity" do
      today = Time.now

      activity = Backbeat::Handler.with_current_activity(parent_activity) do
        Backbeat::Handler.register("cooking-workflow.activity-2", fires_at: today).with(1, 2)
      end

      activity_data = store.find_activity_by_id(activity.id)

      expect(activity_data[:retry_interval]).to eq(10)
    end

    it "signals a new workflow if there is not parent activity set in the current context" do
      activity = Backbeat::Handler.register("cooking-workflow.activity-2", mode: :non_blocking).with(1, 2)

      activity.run
      activity_data = store.find_activity_by_id(activity.id)

      expect(activity_data[:name]).to eq("cooking-workflow.activity-2")
      expect(activity_data[:mode]).to eq(:blocking)
      expect(activity_data[:client_data]).to eq({
        name: "cooking-workflow.activity-2",
        params: [1, 2]
      })
      expect(activity.result).to eq(9)
    end

    it "raises an exception if the activity name is not found" do
      expect {
        Backbeat::Handler.register("cooking-workflow.wrong-activity").with(10)
      }.to raise_error(Backbeat::Handler::ActivityNotFoundError)
    end

    it "does not raise an exception for activities on other clients" do
      expect {
        Backbeat::Handler.register("cooking-workflow.wrong-activity", { client_id: "123" }).with(10)
      }.to_not raise_error
    end
  end

  context "rescue_with" do
    it "calls the rescue handler" do
      activity = Backbeat::Handler.register("cooking-workflow.activity-1", mode: :non_blocking).with(1, 2)

      activity.run
      activity_data = store.find_activity_by_id(activity.id)

      Backbeat::Activity.rescue(activity_data)

      expect(Cooking.rescued).to eq(true)
    end
  end
end
