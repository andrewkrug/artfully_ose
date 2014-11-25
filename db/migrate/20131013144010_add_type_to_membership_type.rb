class AddTypeToMembershipType < ActiveRecord::Migration
  def change
    add_column :membership_types, :type, :string, :default => "SeasonalMembershipType"
  end
end
