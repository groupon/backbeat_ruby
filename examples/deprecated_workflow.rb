$: << File.expand_path("../../lib", __FILE__)

require "backbeat"

class SubtractSomething
  include Backbeat::Workflowable

  def subtract_2(x, y, total)
    new_total = total - x - y
    SubtractSomething.in_context(workflow, :non_blocking).subtract_3(3, 1, 1, new_total)
    SubtractSomething.in_context(workflow).subtract_3(1, 2, 1, new_total)
    workflow.complete
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
    new_total
  end
end

############################
# Using an explicit local context
############################

require "pp"

Backbeat.local do |workflow|
  puts "Testing in a local context"
  result = AddSomething.in_context(workflow).add_3(1, 2, 3, 50).result
  puts "Result: #{result}"
  puts "Activity History:"
  PP.pp workflow.activity_history
end

############################
# Using a remote context
############################

# Use the memory api here just for testing
require "backbeat/memory_store"
store = Backbeat::MemoryStore.new

require "logger"

Backbeat.configure do |config|
  config.context = :remote
  config.store = store
  config.logger = Logger.new(STDOUT)
end

# Send a signal

puts "\nStarting the workflow"

AddSomething.start_context("The workflow subject goes here").add_3(1, 2, 3, 50)

puts "Remote workflow state:"
PP.pp store.find_workflow_by_id(1)

# Receive the activity data

activity_data = store.find_workflow_by_id(1)[:signals]["AddSomething#add_3"]

# Run the activity by continuing the workflow

Backbeat::Workflow.continue(activity_data)

############################
# Using a local context
############################

Backbeat.configure do |config|
  config.context = :local
end

# Sending a signal runs the complete workflow

puts "\nRunning the workflow locally"

Deal = Struct.new(:id)
deal = Deal.new(5)

activity = AddSomething.start_context(deal).add_3(1, 2, 3, 50)

puts "Local workflow history:"
PP.pp activity
