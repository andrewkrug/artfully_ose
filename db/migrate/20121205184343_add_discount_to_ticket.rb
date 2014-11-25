class AddDiscountToTicket < ActiveRecord::Migration
  def change
    add_column :tickets, :discount_id, :integer
    add_index :tickets, :discount_id
  end
end
