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

require 'grape'
require 'backbeat'

Backbeat.configure do |config|
  config.host      = "192.168.59.103"
  config.port      = 9292
  config.client_id = "9ab09c2f-68d5-4e0e-8844-3637eea44254"
  config.auth_token = "H0hcSqi7VPAovzM62ZXueg"
  config.context   = :remote
end

module BackbeatSample
  Logger = Logger.new(STDOUT)

  class BackbeatModel
    class AddSomething
      include Backbeat::Handler

      def add_2(x, y, total)
        new_total = total + x + y
        Logger.info "Output #{new_total}"
        sleep 10
      end
      activity "workflow.add-2", :add_2

      def add_3(x, y, z, total)
        new_total = total + x + y + z
        Logger.info "Output #{new_total}"
        Logger.info "Registering more acitvities"
        sleep 10
        Backbeat.register("workflow.add-2", { mode: :blocking }).with(5, 5, new_total)
        Backbeat.register("workflow.add-2", { mode: :fire_and_foreget }).with(1, 2, new_total)
      end
      activity "workflow.add-3", :add_3
    end

    def self.signal_workflow
      # The following starts a 'signal' to a new or existing workflow
      # for the provided subject and decider.
      subject = { id: 1, name: "AdditionJob" }
      Backbeat.signal("workflow.add-3", subject).with(1, 2, 3, 50)
    end
  end

  class API < Grape::API
    format :json
    prefix :api

    post :activity do
      Logger.info "Running an activity."
      Logger.info params

      Backbeat::Workflow.continue(params)
    end

    post :notification do
      Logger.info params[:error]
    end
  end
end
