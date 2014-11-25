class AddOriginalPriceToItems < ActiveRecord::Migration
  def change
    add_column :items, :original_price, :integer

    Item.all.each do |i|
      i.original_price = i.price
      i.save
    end
  end
end
