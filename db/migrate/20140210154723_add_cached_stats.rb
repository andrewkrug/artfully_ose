class AddCachedStats < ActiveRecord::Migration
  def change
    add_column :shows, :cached_stats, :text
  end
end
