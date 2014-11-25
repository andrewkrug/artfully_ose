class AddActiveToEpt < ActiveRecord::Migration
  def change
    add_column :events_pass_types, :active, :boolean, :default => true
  end
end
