class ChangeDataTypeOfNextPaymentAt < ActiveRecord::Migration
  def self.up
    change_column :subscriptions, :next_payment_at, :datetime
  end

  def self.down
    change_column :subscriptions, :next_payment_at, :date
  end
end
