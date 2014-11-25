class AddImportIdOrdersEvents < ActiveRecord::Migration
  def change
      add_column :orders, :import_id, :integer 
      add_column :events, :import_id, :integer
  end
end
