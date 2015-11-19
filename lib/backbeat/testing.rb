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
  class Testing
    def self.activities
      jobs.map(&:first)
    end

    def self.jobs
      @jobs ||= []
    end

    def self.clear
      @jobs = []
    end

    def self.run
      jobs.each do |(activity, workflow)|
        unless activity.complete? || activity.error
          activity.run_real(workflow)
        end
      end
    end

    def self.set!(testing)
      current = @testing
      @testing = testing
      if block_given?
        begin
          yield
        ensure
          @testing = current
        end
      end
    end

    def self.enable!(&block)
      set!(true, &block)
    end

    def self.disable!(&block)
      set!(false, &block)
    end

    def self.enabled?
      @testing
    end
  end

  class Activity
    alias_method :run_real, :run

    def run(workflow)
      if Testing.enabled?
        Backbeat::Testing.jobs << [self, workflow]
      else
        run_real(workflow)
      end
    end
  end
end
