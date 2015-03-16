$: << File.expand_path("../../lib", __FILE__)

require "pp"
require "backbeat"

class SubtractSomething
  include Backbeat::Contextable

  def subtract_2(x, y, total)
    new_total = total - x - y
    SubtractSomething.in_context(context, :non_blocking).subtract_3(3, 1, 1, new_total)
    SubtractSomething.in_context(context).subtract_3(1, 2, 1, new_total)
    :done
  end

  def subtract_3(x, y, z, total)
    new_total = total - x - y - z
    puts "Total: #{new_total}"
  end
end

class AddSomething
  include Backbeat::Contextable

  def add_2(x, y, total)
    new_total = total + x + y
    SubtractSomething.in_context(context, :blocking, Time.now + 500).subtract_2(1, 2, new_total)
  end

  def add_3(x, y, z, total)
    new_total = total + x + y + z
    AddSomething.in_context(context, :fire_and_forget).add_2(5, 5, new_total)
  end
end

############################
# Using an explicit local context
############################

Backbeat.local do |context|
  puts "Testing in a local context"
  result = AddSomething.in_context(context).add_3(1, 2, 3, 50)
  puts "Result: #{result}"
  puts "Event History:"
  PP.pp context.event_history
end

############################
# Using a remote context
############################

# Use the memory api here just for testing
require_relative "../spec/support/memory_api"
api = Backbeat::MemoryApi.new

Backbeat.configure do |config|
  config.context = Backbeat::Context::Remote
  config.api = api
end

# Send a signal

puts "\nSimulating signalling the workflow"

workflow_data = { decider: "Adding something", subject: "a subject" }

Backbeat::Packer.unpack_context(workflow_data) do |context|
  AddSomething.in_context(context, :signal).add_3(1, 2, 3, 50)
end

puts "Remote workflow state"
PP.pp api.find_workflow_by_id(1)

# Receive the decision data

decision_data = api.find_workflow_by_id(1)[:signals]["AddSomething.add_3"]

# Run the activity

Backbeat::Packer.unpack(decision_data) do |context, action|
  action.run(context)
end

############################
# Using a local context
############################

Backbeat.configure do |config|
  config.context = Backbeat::Context::Local
end

# Sending a signal runs the complete workflow

Backbeat::Packer.unpack_context(workflow_data) do |context|
  puts "\nRunning the workflow locally"

  AddSomething.in_context(context, :signal).add_3(1, 2, 3, 50)

  puts "Local workflow history"
  PP.pp context.event_history
end
