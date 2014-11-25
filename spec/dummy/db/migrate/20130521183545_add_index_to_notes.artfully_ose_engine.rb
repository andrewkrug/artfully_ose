# This migration comes from artfully_ose_engine (originally 20130320192827)
class AddIndexToNotes < ActiveRecord::Migration
  def change
    add_index :notes, :person_id
    add_index :notes, :organization_id
    add_index :notes, :user_id
    add_index :notes, [:person_id, :organization_id]
  end
end
