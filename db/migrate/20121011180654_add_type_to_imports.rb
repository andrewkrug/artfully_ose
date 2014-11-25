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
