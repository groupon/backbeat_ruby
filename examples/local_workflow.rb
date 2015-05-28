$: << File.expand_path("../../lib", __FILE__)

require "backbeat"

class SubtractSomething
  include Backbeat::Workflowable

  def subtract_2(x, y, total)
    new_total = total - x - y
    SubtractSomething.in_context(workflow, :non_blocking).subtract_3(3, 1, 1, new_total)
    SubtractSomething.in_context(workflow).subtract_3(1, 2, 1, new_total)
    workflow.complete_workflow!
    :done
  end

  def subtract_3(x, y, z, total)
    new_total = total - x - y - z
    puts "Total: #{new_total}"
  end
end

class AddSomething
  include Backbeat::Workflowable

  def add_2(x, y, total)
    new_total = total + x + y
    SubtractSomething.in_context(workflow, :blocking, Time.now + 500).subtract_2(1, 2, new_total)
  end

  def add_3(x, y, z, total)
    new_total = total + x + y + z
    AddSomething.in_context(workflow, :fire_and_forget).add_2(5, 5, new_total)
  end
end

############################
# Using an explicit local context
############################

require "pp"

Backbeat.local do |workflow|
  puts "Testing in a local context"
  result = AddSomething.in_context(workflow).add_3(1, 2, 3, 50)
  puts "Result: #{result}"
  puts "Event History:"
  PP.pp workflow.event_history
end

############################
# Using a remote context
############################

# Use the memory api here just for testing
require_relative "../spec/support/memory_api"
api = Backbeat::MemoryApi.new

Backbeat.configure do |config|
  config.context = :remote
  config.api = api
end

# Send a signal

puts "\nSimulating signalling the workflow"

workflow_data = { name: :bob, decider: "Adding something", subject: "a subject" }

workflow = Backbeat::Workflow.new(workflow_data)
AddSomething.in_context(workflow, :signal).add_3(1, 2, 3, 50)

puts "Remote workflow state"
PP.pp api.find_workflow_by_id(1)

# Receive the decision data

decision_data = api.find_workflow_by_id(1)[:signals]["AddSomething.add_3"]

# Run the activity by continuing the workflow

Backbeat::Workflow.continue(decision_data)

############################
# Using a local context
############################

Backbeat.configure do |config|
  config.context = :local
end

# Sending a signal runs the complete workflow

workflow = Backbeat::Workflow.new(workflow_data)
puts "\nRunning the workflow locally"

AddSomething.in_context(workflow, :signal).add_3(1, 2, 3, 50)

puts "Local workflow history"
PP.pp workflow.event_history
