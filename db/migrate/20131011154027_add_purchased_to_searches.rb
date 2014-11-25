class AddPurchasedToSearches < ActiveRecord::Migration
  def change
    add_column :searches, :has_purchased_for, :boolean, :default => true
  end
end
