class AddImportToActions < ActiveRecord::Migration
  def change
    add_column :actions, :import_id, :integer
  end
end
