class AddStarredToNote < ActiveRecord::Migration
  def change
    add_column :notes, :starred, :boolean, :default => false
  end
end
