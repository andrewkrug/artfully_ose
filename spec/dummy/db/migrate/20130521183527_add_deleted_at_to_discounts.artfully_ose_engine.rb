# This migration comes from artfully_ose_engine (originally 20121211193728)
class AddDeletedAtToDiscounts < ActiveRecord::Migration
  def change
    add_column :discounts, :deleted_at, :datetime
  end
end
