class AddIndexToImportRows < ActiveRecord::Migration
  def change
    add_index :import_rows, :import_id
  end
end
