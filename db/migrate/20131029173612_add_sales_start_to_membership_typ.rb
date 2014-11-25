class AddSalesStartToMembershipTyp < ActiveRecord::Migration
  def change
    add_column :membership_types, :sales_start_at, :datetime
    add_column :membership_types, :sales_end_at, :datetime
  end
end
