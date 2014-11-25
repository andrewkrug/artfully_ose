# This migration comes from artfully_ose_engine (originally 20130506173918)
class AddTokenToCart < ActiveRecord::Migration
  def change
    add_column :carts, :token, :string
    add_index  :carts, :token, :unique => true
  end
end
