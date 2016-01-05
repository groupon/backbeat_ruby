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

require "backbeat/api"
require "backbeat/api/http_client"
require "backbeat/memory_store"
require "backbeat/workflow"
require "backbeat/activity"
require "backbeat/workflowable"

module Backbeat
  class Config
    class ConfigurationError < StandardError; end

    attr_accessor :context
    attr_accessor :host
    attr_accessor :port
    attr_accessor :client_id
    attr_accessor :auth_token
    attr_accessor :logger

    attr_writer :context
    def context
      @context || (
        raise ConfigurationError.new("Context not configured")
      )
    end

    attr_writer :store
    def store
      @store ||= (
        case context
        when :remote
          API.new(API::HttpClient.new(host, client_id, auth_token, port))
        when :local
          MemoryStore.new({})
        else
          raise ConfigurationError.new("Unknown default api for context #{context}")
        end
      )
    end

    def local?
      context == :local
    end
  end

  def self.configure
    @config = Config.new
    yield config
    config
  end

  def self.config
    @config ||= Config.new
  end

  def self.local_config
    config = Config.new
    config.context = :local
    config
  end

  def self.local
    yield Workflow.new({ config: local_config })
  end
end
