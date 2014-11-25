# This migration comes from artfully_ose_engine (originally 20130114212408)
class AddLimitToDiscounts < ActiveRecord::Migration
  def change
    add_column :discounts, :limit, :integer
  end
end
