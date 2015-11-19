# Backbeat Ruby Client

Ruby client for [Backbeat](https://github.groupondev.com/backbeat/backbeat_server) workflow service.

## Running the specs

```bash
$ rspec
```

## Running the examples

```bash
$ ruby examples/local_workflow.rb
```

## Usage

Configure:

```ruby
require 'backbeat'

Backbeat.configure do |config|
  config.host      = "your_backbeat_server_host"
  config.port      = "your_backbeat_server_port"
  config.client_id = "your_backbeat_user_id"
  config.context   = :remote
  config.logger    = MyLogger.new("log/mylogs.log")
end
```

Create some workflowable classes:

```ruby
class MyActivities
  include Backbeat::Workflowable

  def activity_one(order_id, customer_id)
    DoSomething.call(order_id)
    MyOtherActivities.in_context(workflow, :non_blocking).send_notification(customer_id)
    MyOtherActivities.in_context(workflow, :blocking, Time.now + 1.day).complete_order(order_id)
    MyOtherActivities.in_context(workflow, :fire_and_forget).mark_complete(order_id)
  end
end

class MyDecider
  include Backbeat::Workflowable

  def the_first_activity(order_id)
    order = Order.find(order_id)
    customer = FindCustomer.call(order)
    if customer.type == :one
      MyActivities.in_context(workflow).activity_one(order_id, customer.id)
    else
      MyActivities.in_context(workflow).activity_two(order_id, customer.id)
    end
  end
end
```

Signal the workflow. The signal is the first node in a workflow execution.
Each signal will wait for previous signals for the provided
subject (the argument to `start_context`) and decider (the class on which
`start_context` is called) combination to finish before executing.

```ruby
order = Order.last
MyDecider.start_context(order).my_decision(order.id)
```

Continue the workflow from your app's activity endpoint. This should match the endpoint
specified when creating a user on the Backbeat server.

```ruby
post 'perform_activity' do
  Backbeat::Workflow.continue(params)
end
```

## Testing

Run a complete workflow locally by configuring a local context:

```ruby
Backbeat.configure do |config|
  config.context = :local
end

order = Order.last
MyDecider.start_context(order).my_decision(order.id)
```

Or:

```ruby
Backbeat.local do |workflow|
  order = Order.last
  MyDecider.start_context(order).my_decision(order.id)
end
```

Make assertions prior to running activities using `Backbeat::Testing`

```ruby
Backbeat.configure do |config|
  config.context = :local
end

Backbeat::Testing.enable!

order = Order.last
MyDecider.start_context(order).my_decision(order.id)

activity = Backbeat::Testing.activities.first

expect(activity.name).to eq("MyDecider#my_decision")
expect(activity.params).to eq([order.id])

Backbeat::Testing.run # Runs all queued activities

Backbeat::Testing.disable!
```
