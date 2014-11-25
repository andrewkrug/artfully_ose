class UniqueHouseholdNames < ActiveRecord::Migration
  def up
    change_column :households, :name, :string, :unique => true
  end

  def down
  end
end
