class AddLegacyAddressIdToSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :legacy_address_id, :integer
  end

  def self.down
    remove_column :subscriptions, :legacy_address_id
  end
end
