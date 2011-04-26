class AddColumnCreatedBySubscriptionIdToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :created_by_subscription_id, :integer
  end

  def self.down
    remove_column :orders, :created_by_subscription_id
  end
end
