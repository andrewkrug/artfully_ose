class AddCategoriesToEvents < ActiveRecord::Migration
  def change
    add_column :events, :primary_category, :string
    add_column :events, :secondary_categories, :text
  end
end