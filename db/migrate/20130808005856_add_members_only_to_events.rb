class AddMembersOnlyToEvents < ActiveRecord::Migration
  def change
    add_column :events, :members_only, :boolean, :default => false
  end
end
