# Copyright (c) 2015, Groupon, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# Neither the name of GROUPON nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

$: << File.expand_path("../../lib", __FILE__)

require 'backbeat'

 Backbeat.configure do |config|
   config.context = :local
   config.store = Backbeat::MemoryStore.new
   config.logger = Logger.new(STDOUT)
 end

Item = Struct.new(:id, :name) do
  def self.find(id)
    if id == 10
      Item.new(10, "book")
    end
  end

  def self.purchases
    @purchases ||= []
  end

  def self.purchased(item_id)
    purchases << item_id
  end
end

Notification = Struct.new(:department) do
  def self.sent
    @sent ||= []
  end

  def send
    Notification.sent << department
  end
end

Package = Struct.new(:item) do
  def self.built
    @build ||= []
  end

  def self.shipped
    @shipped ||= []
  end

  def build
    Package.built << item
  end

  def ship
    Package.shipped << item
  end
end

class BusinessWorkflows
  include Backbeat::Handler

  def purchase(item_id)
    item = Item.find(item_id)
    if item
      Item.purchased(item_id)
      package = Package.new(item_id)
      package.build

      register("business.ship-it").with(item_id)
      register("business.notify-all").with(['accounting', 'sales', 'finance'])
    else
      raise "Item not found"
    end
  end
  activity "business.purchase-item", :purchase

  def notify_all(department_ids)
    department_ids.each do |dept|
      register("business.notify-dept", mode: :non_blocking).with(dept)
    end
  end
  activity "business.notify-all", :notify_all

  def notify(department_id)
    Notification.new(department_id).send
  end
  activity "business.notify-dept", :notify

  def ship(item_id)
    package = Package.new(item_id)
    package.ship
    "Shipped item #{item_id}"
  end
  activity "business.ship-it", :ship
end

item = Item.new(10, "book")

activity = Backbeat.signal("business.purchase-item", item).with(item.id) # This workflow should complete

puts "Workflow status: #{activity.status}"
puts "Purchased items: #{Item.purchases}"
puts "Notified departments: #{Notification.sent}"
puts "Shipped items: #{Package.shipped}"

item = Item.new(11, "table")

activity = Backbeat.signal("business.purchase-item", item).with(item.id) # This workflow should fail with "Item not found"

puts "Workflow status: #{activity.status}"
puts "Activity error: #{activity.error[:message]}"
