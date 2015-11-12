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
require "backbeat/activity/log_decorator"
require "support/mock_logger"

describe Backbeat::Activity::LogDecorator do
  class MockActivity
    def initialize(&activity)
      @run = activity
    end

    def run(workflow)
      @run.call(workflow)
    end
  end

  let(:logger) { Backbeat::MockLogger.new }

  it "logs around running the activity" do
    activity = MockActivity.new { :done }
    decorator = described_class.new(activity, logger)

    decorator.run(:workflow)

    expect(logger.msgs[:info].count).to eq(2)
    expect(logger.msgs[:info].first[:name]).to eq(:activity_started)
    expect(logger.msgs[:info].last[:name]).to eq(:activity_complete)
  end

  it "logs errors in the activity" do
    activity = MockActivity.new { raise "Error" }
    decorator = described_class.new(activity, logger)

    expect { decorator.run(:workflow) }.to raise_error RuntimeError, "Error"

    expect(logger.msgs[:info].count).to eq(1)
    expect(logger.msgs[:info].first[:name]).to eq(:activity_started)
    expect(logger.msgs[:error].count).to eq(1)
    expect(logger.msgs[:error].last[:name]).to eq(:activity_errored)
  end
end
