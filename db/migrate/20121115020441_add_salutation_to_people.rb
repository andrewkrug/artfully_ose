class AddSalutationToPeople < ActiveRecord::Migration
  def change
    add_column :people, :salutation, :string, :default => nil
  end
end
