class AddIndexesToActions < ActiveRecord::Migration
  def change
    add_index :actions, :organization_id
    add_index :actions, :person_id
    add_index :actions, :creator_id
    add_index :actions, :import_id
    add_index :actions, [:organization_id, :person_id]
  end
end
