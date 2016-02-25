# Backbeat Ruby Client

Ruby client for [Backbeat](https://github.groupondev.com/backbeat/backbeat_server) workflow service.

## Running the specs

```bash
$ rspec
```

## Running the examples

```bash
$ ruby examples/workflow.rb
```

## Usage

Configure:

```ruby
require 'backbeat'

Backbeat.configure do |config|
  config.host      = "your_backbeat_server_host"
  config.port      = "your_backbeat_server_port"
  config.client_id = "your_backbeat_user_id"
  config.auth_token = "your_backbeat_auth_token"
  config.context   = :remote
  config.logger    = MyLogger.new("log/mylogs.log")
end
```

Define activity handlers:

```ruby
class PurchaseActivities
  include Backbeat::Handler

  def activity_one(order_id)
    customer_id = FindCustomerId.call(order_id)
    MakePurchase.call(order_id)
    Backbeat.register("purchase.send-notification", mode: :non_blocking).with(customer_id)
    Backbeat.register("purchase.complete-order", at: Time.now + 1.day).with(order_id)
    Backbeat.register("purchase.mark-completed", mode: :fire_and_forget, at: Time.now + 1.day).with(order_id)
  end
  activity "purchase.activity-1", :activity_one

  def send_notification(order_id)
    Notification.send(order_id)
  end
  activity "purchase.send-notification", :send_notification
end
```

Signal the workflow. The signal is the first node in a workflow execution.
Each signal will wait for previous signals for the provided
subject (the second argument to `signal`) and decider (the name of the first
activity that `signal` is called with) combination to finish before executing.

```ruby
order = Order.last
Backbeat.signal("purchase.activity-1", order).with(order.id)
```

Continue the workflow from your app's activity endpoint. This should match the endpoint
specified when creating a user on the Backbeat server.

```ruby
post 'activity' do
  Backbeat::Workflow.continue(params)
end
```

Also define an endpoint to receive notifications of errored activities from Backbeat.

```ruby
post 'notification' do
  Logger.info(params)
end
```

## Testing

Run a complete workflow locally by configuring a local context:

```ruby
Backbeat.configure do |config|
  config.context = :local
end

order = Order.last
Backbeat.signal("purchase.activity-1", order).with(order.id)
```

Make assertions prior to running activities using `Backbeat::Testing`

```ruby
Backbeat.configure do |config|
  config.context = :local
end

Backbeat::Testing.enable!

order = Order.last
Backbeat.signal("purchase.activity-1", order).with(order.id)

activity = Backbeat::Testing.activities.first

expect(activity.name).to eq("purchase.activity-1")
expect(activity.params).to eq([order.id])

Backbeat::Testing.run # Runs all queued activities

Backbeat::Testing.disable!
```
