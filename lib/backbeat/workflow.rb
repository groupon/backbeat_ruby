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

require "backbeat/packer"
require "backbeat/runner"

module Backbeat
  class Workflow
    def self.continue(data)
      workflow = Packer.unpack_workflow(data)
      workflow.run_current
      workflow
    end

    attr_reader :current_activity, :config

    def initialize(options = {})
      @config = options.delete(:config) || Backbeat.config
      @current_activity = options[:current_activity]
      @workflow_data = options
    end

    def deactivate
      store.update_activity_status(current_activity.id, :deactivated)
    end

    def activity_history
      store.find_all_workflow_activities(id)
    end

    def complete?
      !!store.find_workflow_by_id(id)[:complete]
    end

    def complete
      store.complete_workflow(id)
    end

    def signal(activity)
      activity_data = activity.to_hash
      new_id = store.signal_workflow(id, activity_data[:name], activity_data)
      activity.id = new_id
      run(activity) if config.local?
      activity
    end

    def register(activity)
      current_activity.register_child(activity)
      run(activity) if config.local?
      activity
    end

    def run(activity)
      observer.with_workflow(set_current(activity)) do
        activity.run
      end
    end

    def run_current
      observer.with_workflow(self) do
        current_activity.run
      end
    end

    def name
      workflow_data[:name]
    end

    def subject
      workflow_data[:subject] ||= {}
    end

    def decider
      workflow_data[:decider]
    end

    def id
      workflow_data[:id] ||= find_id
    end

    private

    attr_reader :workflow_data

    def store
      config.store
    end

    def observer
      config.run_chain
    end

    def find_id
      workflow = find || create
      workflow[:id]
    end

    def find
      store.find_workflow_by_subject(workflow_params)
    end

    def create
      store.create_workflow(workflow_params)
    end

    def set_current(activity)
      Workflow.new({
        name: name,
        subject: subject,
        decider: decider,
        current_activity: activity,
        config: config
      })
    end

    def workflow_params
      @workflow_params ||= {
        name: name,
        subject: Packer.subject_to_string(subject),
        decider: decider
      }
    end
  end
end
