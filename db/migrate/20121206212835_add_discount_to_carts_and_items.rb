class AddDiscountToCartsAndItems < ActiveRecord::Migration
  def change
    add_column :carts, :discount_id, :integer
    add_column :items, :discount_id, :integer
    add_index :items, :discount_id
  end
end
