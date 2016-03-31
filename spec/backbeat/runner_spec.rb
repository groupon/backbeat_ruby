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
require "backbeat/runner"
require "backbeat"
require "support/mock_logger"

describe Backbeat::Runner do
  class MockActivity
    def initialize(&activity)
      @block = activity
    end

    def object
      Object.new
    end

    def done?
      @done
    end

    def done
      @done = true
    end

    def run
      @block.call
      done
    end

    def params
      [1]
    end

    def name
      "Activity"
    end
  end

  let(:logger) { Backbeat::MockLogger.new }

  let(:workflow) { Object.new }

  it "runs the activity" do
    activity = MockActivity.new { :done }
    runner = described_class.new(logger)

    runner.with_workflow(workflow) do
      runner.running(activity) do
        activity.run
      end
    end

    expect(activity.done?).to eq(true)
  end

  it "logs around running the activity" do
    activity = MockActivity.new { :done }
    runner = described_class.new(logger)

    runner.with_workflow(workflow) do
      runner.running(activity) do
        activity.run
      end
    end

    expect(logger.msgs[:info].count).to eq(2)
    expect(logger.msgs[:info].first[:name]).to eq(:activity_started)
    expect(logger.msgs[:info].last[:name]).to eq(:activity_complete)
  end

  it "logs errors in the activity" do
    activity = MockActivity.new { raise "Error" }
    runner = described_class.new(logger)

    runner.with_workflow(workflow) do
      runner.running(activity) do
        activity.run
      end
    end

    expect(logger.msgs[:info].count).to eq(1)
    expect(logger.msgs[:info].first[:name]).to eq(:activity_started)
    expect(logger.msgs[:error].count).to eq(1)
    expect(logger.msgs[:error].last[:name]).to eq(:activity_errored)
    expect(logger.msgs[:error].last[:message]).to eq("Error")
  end

  let(:new_runner) {
    Class.new do
      def self.called
        @called = true
      end

      def self.called?
        @called
      end

      def initialize(chain, logger)
        @chain = chain
      end

      def call(activity, workflow)
        self.class.called
        @chain.call(activity, workflow)
      end
    end
  }

  it "can be extended with other runners" do
    Backbeat::Runner.chain.add(new_runner)
    activity = MockActivity.new { :done }
    runner = described_class.new(logger)

    runner.with_workflow(workflow) do
      runner.running(activity) do
        activity.run
      end
    end

    Backbeat::Runner.chain.remove(new_runner)

    expect(new_runner.called?).to eq(true)
  end
end
