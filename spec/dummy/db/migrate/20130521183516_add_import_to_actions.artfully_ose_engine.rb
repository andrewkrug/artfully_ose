# This migration comes from artfully_ose_engine (originally 20121006024736)
class AddImportToActions < ActiveRecord::Migration
  def change
    add_column :actions, :import_id, :integer
  end
end
