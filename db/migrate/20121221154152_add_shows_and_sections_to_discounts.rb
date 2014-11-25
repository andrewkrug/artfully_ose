class AddShowsAndSectionsToDiscounts < ActiveRecord::Migration
  def change
    add_column :discounts, :shows_and_sections, :text
  end
end
