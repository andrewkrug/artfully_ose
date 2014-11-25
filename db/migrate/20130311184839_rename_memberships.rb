class RenameMemberships < ActiveRecord::Migration
  def change
    rename_table :memberships, :user_memberships
  end
end
