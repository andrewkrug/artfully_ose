class RemoveExpiresAtFromMembership < ActiveRecord::Migration
  def change
    #Use ends_at instead
    remove_column :memberships, :expires_at
  end
end
