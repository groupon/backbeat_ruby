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
require "backbeat/testing"

describe Backbeat::Testing do

  class ImportWorkflow
    include Backbeat::Workflowable

    def import(thing)
      :import
      ImportWorkflow.in_context(workflow).finish("Imported")
    end

    def finish(message)
      message
    end
  end

  before do
    Backbeat.configure do |config|
      config.context = :local
    end

    Backbeat::Testing.enable!
    Backbeat::Testing.clear
  end

  after do
    Backbeat::Testing.disable!
  end

  it "adds activities to the testing queue rather than running" do
    ImportWorkflow.start_context({ id: 5 }).import("File")

    expect(Backbeat::Testing.activities.count).to eq(1)
    expect(Backbeat::Testing.activities.first.name).to eq("ImportWorkflow#import")
  end

  it "runs all queued activities" do
    ImportWorkflow.start_context({ id: 5 }).import("File")

    Backbeat::Testing.run

    store = Backbeat.config.store
    workflow = store.find_workflow_by_id(1)
    signal = workflow[:signals]["ImportWorkflow#import"]
    activity = store.find_activity_by_id(2)

    expect(signal[:statuses].last).to eq(:completed)
    expect(activity[:statuses].last).to eq(:completed)
    expect(activity[:response][:result]).to eq("Imported")
  end

  it "sets the testing mode for the provided block" do
    activity_1 = nil
    Backbeat::Testing.disable! do
      activity_1 = ImportWorkflow.start_context({ id: 5 }).import("File")
    end

    activity_2 = ImportWorkflow.start_context({ id: 6 }).finish("Done")

    expect(activity_1.complete?).to eq(true)
    expect(activity_2.complete?).to eq(false)
  end

  it "can run without starting a context" do
    ImportWorkflow.new.import("File")

    expect(Backbeat::Testing.activities.first.name).to eq("ImportWorkflow#finish")
    expect(Backbeat::Testing.activities.first.params).to eq(["Imported"])

    Backbeat::Testing.run

    store = Backbeat.config.store
    activity = store.find_activity_by_id(1)

    expect(activity[:statuses].last).to eq(:completed)
    expect(activity[:response][:result]).to eq("Imported")
  end
end
