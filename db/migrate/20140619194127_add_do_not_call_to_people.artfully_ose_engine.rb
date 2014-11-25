class AddDoNotCallToPeople < ActiveRecord::Migration
  def change
    add_column :people, :do_not_call, :boolean, :default => false
  end
end
