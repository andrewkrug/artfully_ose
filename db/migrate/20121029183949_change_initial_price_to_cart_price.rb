class ChangeInitialPriceToCartPrice < ActiveRecord::Migration
  def change
    rename_column :tickets, :initial_price, :cart_price
  end
end
