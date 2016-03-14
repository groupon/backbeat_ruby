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

module Backbeat
  class Runner
    def self.chain
      @chain ||= Chain.new(LogActivity)
    end

    def initialize(logger)
      @logger = logger
    end

    def with_workflow(workflow)
      current = @workflow
      @workflow = workflow
      yield
    ensure
      @workflow = current
    end

    def running(activity)
      Runner.chain.build(@logger) do
        yield
      end.call(activity, @workflow)
    end

    class LogActivity
      def initialize(chain, logger)
        @chain = chain
        @logger = logger
      end

      def call(activity, workflow)
        logger.info(event(activity, :activity_started))
        ret_val = @chain.call(activity, workflow)
        logger.info(event(activity, :activity_complete))
        ret_val
      rescue => e
        logger.error(event(activity, :activity_errored, { message: e.message, backtrace: e.backtrace }))
      end

      private

      attr_reader :logger

      def event(activity, name, options = {})
        { name: name, activity: activity.name, params: activity.params }.merge(options)
      end
    end

    class Chain
      def initialize(*entries)
        @entries = entries
      end

      def add(klass)
        @entries << klass
      end

      def remove(klass)
        @entries.delete(klass)
      end

      def build(logger, &block)
        @entries.reduce(block) do |chain, runner|
          runner.new(chain, logger)
        end
      end
    end
  end
end
