class AddRenewalPriceToMembershipType < ActiveRecord::Migration
  def change
    add_column :membership_types, :renewal_price, :integer, :default => 0
    add_column :membership_types, :offer_renewal, :boolean, :default => false
  end
end
