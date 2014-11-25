# This migration comes from artfully_ose_engine (originally 20121011180654)
class AddTypeToImports < ActiveRecord::Migration
  def up
    add_column :imports, :type, :string
  
    Import.all.each do |i|
      i.type = "PeopleImport"
      i.save
    end
  end
  
  def down
    remove_column :imports, :type
  end
end
