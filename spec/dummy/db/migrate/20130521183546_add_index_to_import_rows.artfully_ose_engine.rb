# This migration comes from artfully_ose_engine (originally 20130324173939)
class AddIndexToImportRows < ActiveRecord::Migration
  def change
    add_index :import_rows, :import_id
  end
end
