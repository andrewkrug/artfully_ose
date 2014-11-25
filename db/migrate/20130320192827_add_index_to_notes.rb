class AddIndexToNotes < ActiveRecord::Migration
  def change
    add_index :notes, :person_id
    add_index :notes, :organization_id
    add_index :notes, :user_id
    add_index :notes, [:person_id, :organization_id]
  end
end
