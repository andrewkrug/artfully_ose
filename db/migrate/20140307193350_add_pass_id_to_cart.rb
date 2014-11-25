class AddPassIdToCart < ActiveRecord::Migration
  def change
    add_column :carts, :applied_pass_id, :integer, :default => nil
    add_column :tickets, :pass_id, :integer, :default => nil
    add_column :items, :pass_id, :integer, :default => nil
  end
end
