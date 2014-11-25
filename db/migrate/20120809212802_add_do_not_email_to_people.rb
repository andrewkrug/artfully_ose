class AddDoNotEmailToPeople < ActiveRecord::Migration
  def change
    add_column :people, :do_not_email, :boolean, :default => false
  end
end
