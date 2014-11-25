class AddTokenToCart < ActiveRecord::Migration
  def change
    add_column :carts, :token, :string
    add_index  :carts, :token, :unique => true
  end
end
