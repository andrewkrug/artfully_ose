class AddMemberNumber < ActiveRecord::Migration
  def change
    add_column :members, :member_number, :string, :null => false
  end
end
