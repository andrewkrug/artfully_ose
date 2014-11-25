class AddServiceFeeToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :service_fee, :integer, :default => 0
  end
end
