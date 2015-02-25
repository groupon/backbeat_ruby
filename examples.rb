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

# Parse response

decision_data = {
  id: 1,
  name: "name",
  workflow_id: 2,
  client_data: {
    argumentss: [1, 2, 3]
  },
  subject: {
    class: "Subject",
    id: 123
  },
  decider: "Decider"
}

performer = Backbeat.build_performer(decision_data)
subject = Backbeat.build_subject(decision_data)
context = Backbeat.build_context(decision_data)

# Perform

performer.call(subject, context)

class FirstDecision
  def self.call(subject, context)
    context.deciding
    context.add_activity(
      name: MyActivity,
      arguments: [1, 2, 3],
      mode: :nonblocking,
      fires_at: Time.now + 5.days
    )
    context.add_activity(
      name: MyActivity2,
      arguments: { key: :value },
      mode: :blocking
    )
    context.complete
  end
end

class MyActivity
  def self.call(subject, context)
    subject.update_attributes(context.arguments)
    context.complete
  end
end
