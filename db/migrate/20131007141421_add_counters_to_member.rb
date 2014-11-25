class AddCountersToMember < ActiveRecord::Migration
  def change
    add_column :members, :current_memberships_count,  :integer, :default => 0
    add_column :members, :lapsed_memberships_count,   :integer, :default => 0
    add_column :members, :past_memberships_count,     :integer, :default => 0
  end
end
