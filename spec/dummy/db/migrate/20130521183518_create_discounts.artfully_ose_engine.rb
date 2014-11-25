# This migration comes from artfully_ose_engine (originally 20121024143846)
class CreateDiscounts < ActiveRecord::Migration
  def change
    create_table :discounts do |t|
      t.string :code, :null => false
      t.boolean :active, :null => false, :default => true
      t.string :promotion_type, :null => false
      t.text :properties
      t.integer :event_id, :null => false
      t.integer :organization_id, :null => false
      t.integer :user_id, :null => false

      t.timestamps
    end
  end
end
