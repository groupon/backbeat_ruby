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

describe Backbeat do

  context "config" do
    it "allows the default context to be configured" do
      Backbeat.configure do |config|
        config.context = :remote
      end

      expect(Backbeat.config.context).to eq(:remote)
    end

    it "allows the backbeat host to be configured" do
      Backbeat.configure do |config|
        config.host = "http://backbeat.com"
      end

      expect(Backbeat.config.host).to eq("http://backbeat.com")
    end

    it "allows the backbeat client id to be configured" do
      Backbeat.configure do |config|
        config.client_id = "123"
      end

      expect(Backbeat.config.client_id).to eq("123")
    end

    it "allows the auth token to be configured" do
      Backbeat.configure do |config|
        config.auth_token = "456"
      end

      expect(Backbeat.config.auth_token).to eq("456")
    end

    it "allows the backbeat store to be configured" do
      Backbeat.configure do |config|
        config.store = { activities: [1, 2] }
      end

      expect(Backbeat.config.store).to eq({ activities: [1, 2] })
    end

    it "allows the logger to be configured" do
      logger = Logger.new("/dev/null")
      Backbeat.configure do |config|
        config.logger = logger
        config.logger.level = Logger::WARN
      end

      expect(Backbeat.config.logger).to eq(logger)
      expect(logger.level).to eq(Logger::WARN)
    end

    it "defaults to the backbeat api in a remote context" do
      Backbeat.configure do |config|
        config.context = :remote
      end

      expect(Backbeat.config.store).to be_a(Backbeat::API)
    end

    it "defaults to a memory store in a local context" do
      Backbeat.configure do |config|
        config.context = :local
      end

      expect(Backbeat.config.store).to be_a(Backbeat::MemoryStore)
    end

    it "defaults logger to configured logger when using local context" do
      logger = Logger.new("/dev/null")
      Backbeat.configure do |config|
        config.logger = logger
      end
      local_context = Backbeat::Config.local

      expect(local_context.logger).to be(logger)
    end

    it "raises an error if the context is unknown" do
      Backbeat.configure do |config|
        config.context = :foo
      end

      expect { Backbeat.config.store }.to raise_error Backbeat::Config::ConfigurationError
    end

    it "raises an error if the context is not configured" do
      Backbeat.configure { |_| }

      expect { Backbeat.config.context }.to raise_error Backbeat::Config::ConfigurationError

      Backbeat.configure do |config|
        config.context = :local
      end

      expect { Backbeat.config.context }.to_not raise_error
    end

    it "allows client ids to be configured" do
      Backbeat.configure do |config|
        config.client(:apples, '12345')
        config.client(:oranges, '54321')
      end

      expect(Backbeat.config.client(:apples)).to eq('12345')
      expect(Backbeat.config.client(:oranges)).to eq('54321')
    end

    it "raises an exception if a client is not configured" do
      Backbeat.configure do |config|
        config.client(:apples, '12345')
      end

      expect { Backbeat.config.client(:bananas) }.to raise_error(Backbeat::Config::ConfigurationError)
    end
  end

  it "yields a local workflow to use" do
    Backbeat.local do |workflow|
      workflow.complete

      expect(workflow.complete?).to eq(true)
    end
  end
end

