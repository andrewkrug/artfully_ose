# This migration comes from artfully_ose_engine (originally 20130114200128)
class AddDiscountCodeToSearch < ActiveRecord::Migration
  def change
    add_column :searches, :discount_code, :string
  end
end
