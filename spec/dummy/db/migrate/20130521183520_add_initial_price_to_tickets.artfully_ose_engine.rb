# This migration comes from artfully_ose_engine (originally 20121026203948)
class AddInitialPriceToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :initial_price, :integer
  end
end
