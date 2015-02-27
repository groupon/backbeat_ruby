$: << File.expand_path("../../lib", __FILE__)

require "backbeat"

class SubtractSomething
  extend Backbeat::Contextable

  def self.subtract_2(x, y, total)
    new_total = total - x - y
    SubtractSomething.in_context_non_blocking(context).subtract_3(3, 1, 1, new_total)
    SubtractSomething.in_context_blocking(context, Time.now).subtract_3(1, 2, 1, new_total)
    :done
  end

  def self.subtract_3(x, y, z, total)
    new_total = total - x - y - z
    puts "total"
    puts new_total
  end
end

class AddSomething
  extend Backbeat::Contextable

  def self.add_2(x, y, total)
    new_total = total + x + y
    SubtractSomething.in_context(context, mode: :blocking, fires_at: Time.now).subtract_2(1, 2, new_total)
  end

  def self.add_3(x, y, z, total)
    new_total = total + x + y + z
    AddSomething.in_context_fire_forget(context).add_2(5, 5, new_total)
  end
end

Backbeat.configure do |config|
  config.context = Backbeat::Context::Local
end

result = AddSomething.add_3(1, 2, 3, 50)
puts "\nResult:"
puts result
puts

context = Backbeat::Context::Local.new({})
result = AddSomething.in_context(context).add_3(1, 2, 3, 50)
puts "\nResult:"
puts result
puts "\nEvent History:"
p context.event_history
puts

puts "Remote Context"
Backbeat.configure do |config|
  config.context = Backbeat::Context::Remote
end


require_relative "../spec/support/memory_api"
api = Backbeat::MemoryApi.new({ workflows: { 2 => { signals: {} }}})

# Send a signal

starting_context = Backbeat::Packer.unpack_context({ workflow_id: 2 }, api)

AddSomething.in_context_signal(starting_context).add_3(1, 2, 3, 50)

# Receive the decision data

decision_data = api.find_workflow_by_id(2)[:signals]["AddSomething.add_3"]

# Build the decision
context = Backbeat::Packer.unpack_context(decision_data, api)
action = Backbeat::Packer.unpack_action(decision_data)

# Run the activity
action.run(context)

p api.find_workflow_by_id(2)
