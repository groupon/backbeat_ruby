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
    include Backbeat::Handler

    def import(thing)
      register("import.finish").with("Imported")
      :imported
    end
    activity "import.start", :import

    def finish(message)
      message
    end
    activity "import.finish", :finish
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
    Backbeat.register("import.start", { id: 5 }).with("File")

    expect(Backbeat::Testing.activities.count).to eq(1)
    expect(Backbeat::Testing.activities.first.name).to eq("import.start")
  end

  it "runs all queued activities" do
    Backbeat.register("import.start", { id: 5 }).with("File")

    Backbeat::Testing.run

    signal = Backbeat::Testing.activities.first
    activity = Backbeat::Testing.activities.last

    expect(signal.name).to eq("import.start")
    expect(signal.complete?).to eq(true)
    expect(activity.name).to eq("import.finish")
    expect(activity.complete?).to eq(true)
    expect(activity.result).to eq("Imported")
  end

  it "does not run already ran activities" do
    Backbeat.register("import.start", { id: 5 }).with("File")

    expect_any_instance_of(ImportWorkflow).to receive(:import).once

    Backbeat::Testing.run
    Backbeat::Testing.run
  end

  it "sets the testing mode for the provided block" do
    activity_1 = nil
    Backbeat::Testing.disable! do
      activity_1 = Backbeat.register("import.start", { id: 5 }).with("File")
    end

    activity_2 = Backbeat.register("import.finish", { id: 5 }).with("File")

    expect(activity_1.complete?).to eq(true)
    expect(activity_2.complete?).to eq(false)
  end

  it "can run without starting a context" do
    ImportWorkflow.new.import("File")

    activity = Backbeat::Testing.activities.first

    expect(activity.name).to eq("import.finish")
    expect(activity.params).to eq(["Imported"])

    Backbeat::Testing.run

    expect(activity.complete?).to eq(true)
    expect(activity.result).to eq("Imported")
  end
end
