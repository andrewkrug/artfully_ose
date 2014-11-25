class AddHouseholds < ActiveRecord::Migration
  def up
    create_table :households do |t|
      t.string :name
      t.references :organization
      t.timestamps
    end

    add_column :people, :household_id, :integer
    add_column :addresses, :household_id, :integer
  end

  def down
    remove_column :addresses, :household_id
    remove_column :people, :household_id
    drop_table :households
  end
end
