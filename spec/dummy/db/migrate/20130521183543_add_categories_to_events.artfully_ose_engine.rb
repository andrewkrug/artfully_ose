# This migration comes from artfully_ose_engine (originally 20130312173340)
class AddCategoriesToEvents < ActiveRecord::Migration
  def change
    add_column :events, :primary_category, :string
    add_column :events, :secondary_categories, :text
  end
end