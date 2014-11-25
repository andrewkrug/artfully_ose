# This migration comes from artfully_ose_engine (originally 20121221154152)
class AddShowsAndSectionsToDiscounts < ActiveRecord::Migration
  def change
    add_column :discounts, :shows_and_sections, :text
  end
end
