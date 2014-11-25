class RemoveTicketsPurchasedFromPasses < ActiveRecord::Migration
  def change
    remove_column :passes, :tickets_purchased
  end
end
