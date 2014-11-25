class AddFeeToTicketsAndDonations < ActiveRecord::Migration
  def change
    add_column :tickets, :service_fee, :integer, :default => 0
    add_column :donations, :service_fee, :integer, :default => 0
    add_column :items, :service_fee, :integer, :default => 0
    rename_column :orders, :service_fee, :old_service_fee
  end
end
