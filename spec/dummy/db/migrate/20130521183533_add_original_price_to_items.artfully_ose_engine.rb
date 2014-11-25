# This migration comes from artfully_ose_engine (originally 20130108213102)
class AddOriginalPriceToItems < ActiveRecord::Migration
  def change
    add_column :items, :original_price, :integer

    Item.all.each do |i|
      i.original_price = i.price
      i.save
    end
  end
end
