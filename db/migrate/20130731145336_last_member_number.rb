class LastMemberNumber < ActiveRecord::Migration
  def change
    add_column :organizations, :last_member_number, :integer, :default => 0
  end
end
