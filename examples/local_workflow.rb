$: << File.expand_path("../../lib", __FILE__)

require "backbeat"

Backbeat.configure do |config|
  config.context = Backbeat::Context::Local
end

class SubtractSomething
  extend Backbeat::Contextable

  def self.subtract_2(x, y, total)
    new_total = total - x - y
    context.blocking(Time.now).run(
      Backbeat::Actors::Activity.build("Sub 3", SubtractSomething, :subtract_3, 3, 1, 1, new_total)
    )
    context.blocking(Time.now).run(
      Backbeat::Actors::Activity.build("Sub 3 again", SubtractSomething, :subtract_3, 1, 2, 1, new_total)
    )
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
    context.blocking(Time.now).run(
      Backbeat::Actors::Activity.build("Add 3", SubtractSomething, :subtract_2, 1, 2, new_total)
    )
  end

  def self.add_3(x, y, z, total)
    # TODO: Ideal DSL
    SubtractSomething.with_context(context, :blocking, Time.now).call(a, b, c)
  end
end

decision_data = {
  id: 1,
  name: "Adding things",
  workflow_id: 2,
  client_data: {
    action: {
      type: "Activity",
      class: AddSomething,
      method: :add_2,
      args: [1, 2, 50]
    }
  },
  subject: "not important",
  decider: "not important in local context"
}

context = Backbeat::Packer.unpack_context(decision_data)
action = Backbeat::Packer.unpack_action(decision_data)

result = context.now.run(action)
puts "\nResult:"
puts result
