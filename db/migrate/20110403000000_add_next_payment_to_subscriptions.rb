class AddNextPaymentToSubscription < ActiveRecord::Migration
  def self.up
		add_column :subscriptions, :next_payment, :datetime
  end

  def self.down
		remove_column :subscriptions, :next_payment
  end
end

