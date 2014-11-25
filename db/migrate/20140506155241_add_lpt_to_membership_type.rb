class AddLptToMembershipType < ActiveRecord::Migration
  def change
    add_column :membership_types, :limit_per_transaction, :integer, :default => 1
  end
end
