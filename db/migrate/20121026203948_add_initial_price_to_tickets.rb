class AddInitialPriceToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :initial_price, :integer
  end
end
