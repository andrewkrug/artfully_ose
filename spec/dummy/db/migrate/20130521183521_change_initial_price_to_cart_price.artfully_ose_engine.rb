# This migration comes from artfully_ose_engine (originally 20121029183949)
class ChangeInitialPriceToCartPrice < ActiveRecord::Migration
  def change
    rename_column :tickets, :initial_price, :cart_price
  end
end
