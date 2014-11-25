# This migration comes from artfully_ose_engine (originally 20130111211929)
class ConvertDiscountsSectionsToArrayOfStrings < ActiveRecord::Migration
  def up
    add_column :discounts, :sections, :text
    drop_table :discounts_sections
  end

  def down
    create_table(:discounts_sections) do |t|
      t.integer :discount_id, :null => false
      t.integer :section_id, :null => false
    end
    remove_column :discounts, :sections
  end
end
