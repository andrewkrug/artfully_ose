# This migration comes from artfully_ose_engine (originally 20130319110520)
class AddTransactionIdIndex < ActiveRecord::Migration
  def change
    add_index :gateway_transactions,  :transaction_id
    add_index :orders,                :transaction_id
  end
end
