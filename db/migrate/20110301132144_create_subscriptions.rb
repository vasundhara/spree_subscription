class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.date :next_payment_at
			t.integer :duration
			t.string :interval
			t.string :state
			t.references :user
			t.references :variant
			t.integer :created_by_order_id
      t.timestamps
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
