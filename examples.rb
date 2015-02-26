# Initialize

Backbeat.configure do |config|
  config.host = "http://localhost:3000"
  config.client_id = "123"
  config.context = Backbeat::Context::Remote
  # or
  config.context = Backbeat::Context::Local
end

# Signal

Backbeat.signal(
  :make_payment,
  subject: subject,
  decider: FirstDecision
)

# Assume signal if no current context?
#
Backbeat::Context.perform(action)

# Parse response

decision_data = {
  "id" => 1,
  "name" => "name",
  "workflow_id" => 2,
  "client_data" => {
    action: {
    "class" => "FirstDecision"
    "method" => "decision_1"
    }
    args: []
  },
  "subject" => {
    "class" => "Subject",
    "id" => 123
  },
  "decider" => "Decider"
}

context, current_node = Backbeat::Packer.unpack(decision_data)
# build subject object
# build client_data object
# build client_data arguments
# get client_data method
# get decider class

Backbeat::Context.perform(context, current_node)

# Perform
#
# Case client_data
# When nothing
#   Decider.new(context).call(subject)
# When just class
#   Class.new(context).call(subject)
# When class and arguments
#   Class.new(context).call(*arguments)
# When class and method
#   Class.new(context).method(subject)
# When class, method, arguments
#   Class.new(context).method(*arguments)
# *ActiveRecord Packer*
# When class, id, method, arguments
#   Class.find(id).method(arguments)

# Testing

context = Backbeat::Context::Remote.new(
  workflow_id: 1
)

context = Backbeat::Context::Remote.new(
  workflow_name: "A",
  subject: "B",
  decider: "C"
)

MyCommand.with_context(context) do |command|
  command.perform(payment_term)
end

MyCommand.new(context).perform(payment_term)

# Worker

context = Backbeat::Context::Remote.new(
  workflow_id: 1,
  event_id: 2
)

action = Backbeat::Action.new(
  name: "My action",
  class: MyCommand,
  method: :perform,
  args: [1, 2, 3]
)

action.run(context)

class MyCommand
  include Contextable

  def perform(a, b, c)
    context.fire_and_forget.run(Activity.build(MyActivity, :foo, payment_term, 1))
  end
end
