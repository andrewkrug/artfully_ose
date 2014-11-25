class AddMiddleNameAndSuffixToPeople < ActiveRecord::Migration
  def change
  	add_column :people, :middle_name, :string
  	add_column :people, :suffix, :string
  end
end
