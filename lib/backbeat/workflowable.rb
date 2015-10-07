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

require "backbeat/serializer/activity"
require "backbeat/serializer/findable_activity"

module Backbeat
  module Workflowable
    def self.included(klass)
      klass.extend(InContext)
    end

    def workflow
      @workflow ||= Workflow.new({})
    end

    def with_context(current_workflow)
      @workflow = current_workflow
      yield
    ensure
      @workflow = nil
    end

    module InContext
      def in_context(workflow, mode = :blocking, fires_at = nil)
        ContextProxy.new(self, workflow, { mode: mode, fires_at: fires_at })
      end

      def start_context(subject)
        workflow = new_workflow(subject)
        ContextProxy.new(self, workflow, { mode: :signal })
      end

      def link_context(link_workflow, subject)
        workflow = new_workflow(subject)
        link_id = link_workflow.activity_id
        options = { mode: :signal, parent_link_id: link_id }
        ContextProxy.new(self, workflow, options)
      end

      def serializer
        Serializer::Activity
      end

      private

      def new_workflow(subject)
        name = self.is_a?(Class) ? self.to_s : self.class.to_s
        Workflow.new({
          subject: subject,
          decider: name,
          name: name
        })
      end
    end

    class ContextProxy
      def initialize(workflowable, workflow, options)
        @workflowable = workflowable
        @workflow = workflow
        @options = options
      end

      def method_missing(method, *params)
        activity = Activity.build(build_serializer(method, params))
        if options[:mode] == :signal
          workflow.signal_workflow(activity, options)
        else
          workflow.run_activity(activity, options)
        end
      end

      private

      attr_reader :workflowable, :workflow, :options

      def build_serializer(method, params)
        workflowable.serializer.build(
          build_name(method),
          workflowable,
          method,
          params
        )
      end

      def build_name(method)
        if workflowable.is_a?(Class)
          "#{workflowable.to_s}##{method}"
        else
          "#{workflowable.class.to_s}##{method}"
        end
      end
    end
  end

  module WorkflowableModel
    include Workflowable
    include Workflowable::InContext

    def serializer
      Serializer::FindableActivity
    end
  end
end
