class AddStarredToRelationships < ActiveRecord::Migration
  def change
    add_column :relationships, :starred, :boolean, :default => false
  end
end
