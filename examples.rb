# Initialize

Backbeat.configure do |config|
  config.host = "http://localhost:3000"
  config.client_id = "123"
  config.context = Backbeat::Context::Remote
  # or
  config.context = Backbeat::Context::Local
end

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
  include Backbeat::Contextable

  def perform(a, b, c)
    context.fire_and_forget(Time.now + 5.days).run(Activity.build(MyActivity, :foo, payment_term, 1))
  end
end
