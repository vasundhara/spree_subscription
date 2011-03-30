class AddPriceToSubscription < ActiveRecord::Migration
  def self.up
		add_column :subscriptions, :price, :float
  end

  def self.down
		remove_column :subscriptions, :price
  end
end
