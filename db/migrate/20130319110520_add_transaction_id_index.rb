class AddTransactionIdIndex < ActiveRecord::Migration
  def change
    add_index :gateway_transactions,  :transaction_id
    add_index :orders,                :transaction_id
  end
end
