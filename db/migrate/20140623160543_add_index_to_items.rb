class AddIndexToItems < ActiveRecord::Migration
  def change
    add_index :items, :product_id
    add_index :items, :product_type
    add_index :items, [:product_id, :product_type]
  end
end
