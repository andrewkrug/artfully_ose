# This migration comes from artfully_ose_engine (originally 20121205184343)
class AddDiscountToTicket < ActiveRecord::Migration
  def change
    add_column :tickets, :discount_id, :integer
    add_index :tickets, :discount_id
  end
end
