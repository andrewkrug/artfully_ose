class AddImportMessages < ActiveRecord::Migration
  def change
    create_table :import_messages do |t|
      t.references  :import
      t.references  :person
      t.integer     :row_number
      t.text        :row_data
      t.text        :message
      t.datetime    :deleted_at

      t.timestamps
    end 

    add_index :import_messages, :import_id

  end
end
