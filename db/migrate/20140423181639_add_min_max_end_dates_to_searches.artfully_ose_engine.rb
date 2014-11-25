class AddMinMaxEndDatesToSearches < ActiveRecord::Migration
  def change
    add_column :searches, :min_membership_end_date, :datetime
    add_column :searches, :max_membership_end_date, :datetime
  end
end
