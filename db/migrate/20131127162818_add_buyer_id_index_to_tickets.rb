class AddBuyerIdIndexToTickets < ActiveRecord::Migration
  def change
    add_index :tickets, :buyer_id
  end
end
