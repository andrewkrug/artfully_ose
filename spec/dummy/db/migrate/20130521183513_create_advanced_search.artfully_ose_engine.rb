# This migration comes from artfully_ose_engine (originally 20120831200120)
class CreateAdvancedSearch < ActiveRecord::Migration
  def change
    create_table :segments, :force => true do |t|
      t.string  :name,            :null => false
      t.integer :organization_id, :null => false
      t.integer :search_id,       :null => false

      t.timestamps
    end
    add_index :segments, :organization_id
    add_index :segments, :search_id

    create_table "searches" do |t|
      t.integer  "organization_id",      :null => false
      t.string   "zip"
      t.string   "state"
      t.integer  "event_id"
      t.integer  "min_lifetime_value"
      t.integer  "min_donations_amount"
      t.integer  "max_lifetime_value"
      t.integer  "max_donations_amount"
      t.datetime "min_donations_date"
      t.datetime "max_donations_date"
      t.string   "tagging"

      t.timestamps
    end
    add_index :searches, :organization_id
  end
end
