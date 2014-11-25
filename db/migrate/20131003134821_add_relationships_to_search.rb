class AddRelationshipsToSearch < ActiveRecord::Migration
  def change
    change_table :searches do |t|
      t.integer :relation_id
    end
  end
end
