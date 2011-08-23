class AddDeclinedCountToSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :declined_count, :integer, :default => 0
  end

  def self.down
    remove_column :subscriptions, :declined_count
  end
end
