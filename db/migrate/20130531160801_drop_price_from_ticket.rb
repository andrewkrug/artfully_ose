class DropPriceFromTicket < ActiveRecord::Migration
  def change
    remove_column :tickets, :price
  end
end
