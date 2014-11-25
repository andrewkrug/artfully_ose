# This migration comes from artfully_ose_engine (originally 20130103153946)
class MakeShowsAndSectionsHabtm < ActiveRecord::Migration
  def up
    create_table(:discounts_shows) do |t|
      t.integer :discount_id, :null => false
      t.integer :show_id, :null => false
    end
    create_table(:discounts_sections) do |t|
      t.integer :discount_id, :null => false
      t.integer :section_id, :null => false
    end
    remove_column :discounts, :shows_and_sections
  end

  def down
    drop_table :discounts_shows
    drop_table :discounts_sections
    add_column :discounts, :shows_and_sections, :text
  end
end
