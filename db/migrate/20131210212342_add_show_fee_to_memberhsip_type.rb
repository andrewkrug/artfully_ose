class AddShowFeeToMemberhsipType < ActiveRecord::Migration
  def change
    add_column :membership_types, :hide_fee, :boolean, :default => false
  end
end
