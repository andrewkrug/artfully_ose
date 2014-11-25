class AddLifetimeMembershipsToPeople < ActiveRecord::Migration
  def change
    add_column :people, :lifetime_memberships, :integer, :default => 0
  end
end
