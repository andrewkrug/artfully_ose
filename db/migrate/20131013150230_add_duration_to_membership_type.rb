class AddDurationToMembershipType < ActiveRecord::Migration
  def change
    add_column :membership_types, :duration, :integer 
    add_column :membership_types, :period, :string
  end
end