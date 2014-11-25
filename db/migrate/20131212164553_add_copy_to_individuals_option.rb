class AddCopyToIndividualsOption < ActiveRecord::Migration
  def change
    add_column :households, :overwrite_member_addresses, :boolean, :default => true, :null => false
  end
end
