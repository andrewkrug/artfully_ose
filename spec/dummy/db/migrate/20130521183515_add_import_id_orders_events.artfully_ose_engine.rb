# This migration comes from artfully_ose_engine (originally 20121001143351)
class AddImportIdOrdersEvents < ActiveRecord::Migration
  def change
      add_column :orders, :import_id, :integer 
      add_column :events, :import_id, :integer
  end
end
