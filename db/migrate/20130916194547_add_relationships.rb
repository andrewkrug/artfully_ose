class AddRelationships < ActiveRecord::Migration
  def change
    create_table :relationships do |t|
      t.integer :person_id,   :null => false
      t.integer :relation_id, :null => false
      t.integer :other_id,    :null => false
      t.integer :inverse_id
      t.timestamps
    end

    create_table :relations do |t|
      t.string :description
      t.boolean :person_can_be_individual, :default => false
      t.boolean :person_can_be_company,    :default => false
      t.boolean :other_can_be_individual,  :default => false
      t.boolean :other_can_be_company,     :default => false
      t.integer :inverse_id
      t.timestamps
    end
  end
end
