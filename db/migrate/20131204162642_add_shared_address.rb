class AddSharedAddress < ActiveRecord::Migration
  def up
    add_column :households, :shared_address, :boolean, :default => true
  end

  def down
    remove_column :households, :shared_address
  end
end
