# Backbeat Ruby Client

Ruby client for [Backbeat](https://github.groupondev.com/finance-engineering/backbeat) workflow service.

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
  config.host      = "http://your_backbeat_host"
  config.client_id = "your_backbeat_user_id"
  config.context   = Backbeat::Context::Remote
end
```

Create some decider/activity/decision classes:

```ruby
class MyActivities
  include Backbeat::Contextable

  def activity_one(order, customer)
    DoSomething.call(order)
    MyOtherActivities.in_context(current, :non_blocking).send_notification(customer)
    MyOtherActivities.in_context(current, :blocking, Time.now + 1.day).complete_order(order)
    MyOtherActivities.in_context(current, :fire_and_forget).mark_complete(order)
  end
end

class MyDecider
  include Backbeat::Contextable

  def my_decision(subject)
    customer = FindCustomer.call(subject)
    if subject[:type] == :one
      MyActivities.in_context(current).activity_one(subject, customer)
    else
      MyActivities.in_context(current).activity_two(subject, customer)
    end
  end
end
```

Signal the workflow:

```ruby
subject = Order.last.to_hash
context = Backbeat::Packer.unpack_context(subject: subject, decider: "MyDecider")
MyDecider.in_context(context, :signal).my_decision(subject)
```

Continue the workflow from your app's activity endpoint:

```ruby

post "/perform_activity" do
  Backbeat::Packer.continue(params)
end
```

## Testing

Run a complete workflow locally by configuring a local context:

```ruby
Backbeat.configure do |config|
  config.context = Backbeat::Context::Local
end

subject = Order.last.to_hash
context = Backbeat::Packer.unpack_context(subject: subject, decider: "MyDecider")
MyDecider.in_context(context, :signal).my_decision(subject)
```

Or:

```ruby
Backbeat.local do |context|
  subject = Order.last.to_hash
  MyDecider.in_context(context, :signal).my_decision(subject)
end
```
