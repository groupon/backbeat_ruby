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
  module Handler
    ActivityRegistrationError = Class.new(StandardError)
    ActivityNotFoundError = Class.new(StandardError)

    extend self

    def self.__handlers__
      @__handlers__ ||= {}
    end

    def self.add(activity_name, klass, method_name, options = {})
      __handlers__[activity_name] = {
        class: klass,
        method: method_name,
        options: options
      }
    end

    def self.find(activity_name)
      __handlers__[activity_name] || {}
    end

    def self.included(klass)
      klass.extend(Registration)
    end

    ACTIVITY = :backbeat_activity

    def current_activity
      Thread.current[ACTIVITY]
    end

    def with_current_activity(activity)
      previous = Thread.current[ACTIVITY]
      Thread.current[ACTIVITY] = activity
      yield
    ensure
      Thread.current[ACTIVITY] = previous
    end

    def register(activity_name, options = {})
      if Handler.current_activity
        ActivityBuilder.new(activity_name, options)
      else
        signal(activity_name, {}, options)
      end
    end

    def signal(activity_name, subject, options = {})
      SignalBuilder.new(activity_name, subject, options)
    end

    private

    class ActivityBuilder
      attr_reader :name, :options, :parent

      def initialize(name, options)
        @name = name
        @options = options
        @parent = Handler.current_activity
      end

      def call(*params)
        client_id = lookup_client_id(options)
        registration_data = Handler.find(name)

        if client_id.nil? && registration_data.empty?
          raise ActivityNotFoundError, "Activity #{name} not found"
        end

        registered_options = registration_data[:options] || {}

        activity = Activity.new({
          config: parent.config,
          name: name,
          mode: options[:mode],
          fires_at: options[:fires_at] || options[:at],
          retry_interval: registered_options[:backoff],
          client_id: client_id,
          params: params,
          client_data: { name: name }
        }.merge(registration_data))

        parent.register_child(activity)
      end
      alias_method :with, :call

      def lookup_client_id(options)
        if id = options[:client_id]
          id
        elsif client_name = options[:client]
          parent.config.client(client_name)
        end
      end
    end

    class SignalBuilder
      attr_reader :name, :subject, :options

      def initialize(name, subject, options)
        @name = name
        @subject = subject
        @options = options
      end

      def call(*params)
        workflow = Workflow.new({
          config: options[:config],
          subject: subject,
          decider: name,
          name: name
        })

        client_id = lookup_client_id(workflow, options)
        registration_data = Handler.find(name)

        if client_id.nil? && registration_data.empty?
          raise ActivityNotFoundError, "Activity #{name} not found"
        end

        registered_options = registration_data[:options] || {}

        activity = Activity.new({
          config: workflow.config,
          name: name,
          mode: :blocking,
          fires_at: options[:fires_at],
          retry_interval: registered_options[:backoff],
          client_id: client_id,
          params: params,
          client_data: { name: name }
        }.merge(registration_data))

        workflow.signal(activity)
      end
      alias_method :with, :call

      def lookup_client_id(workflow, options)
        if id = options[:client_id]
          id
        elsif client_name = options[:client]
          workflow.config.client(client_name)
        end
      end
    end

    module Registration
      def activity(activity_name, method_name, options = {})
        klass = self
        if klass.method_defined?(method_name)
          Handler.add(activity_name, klass, method_name, options)
        else
          raise ActivityRegistrationError, "Method #{method_name} does not exist"
        end
      end
    end

    class CurrentActivityRunner
      def initialize(chain, _)
        @chain = chain
      end

      def call(activity, workflow)
        Handler.with_current_activity(activity) do
          @chain.call(activity, workflow)
        end
      end
    end
    Runner.chain.add(CurrentActivityRunner)
  end
end
