class RemovePriceFromSection < ActiveRecord::Migration
  def change
    remove_column :sections, :price
  end
end
