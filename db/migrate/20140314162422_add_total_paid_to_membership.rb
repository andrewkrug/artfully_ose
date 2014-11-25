class AddTotalPaidToMembership < ActiveRecord::Migration
  def change
    add_column :memberships, :cart_price, :integer
    add_column :memberships, :total_paid, :integer
    add_column :memberships, :changed_membership_id, :integer, :defult => nil

    Membership.all.each do |membership|
      membership.cart_price = membership.sold_price
      membership.total_paid = membership.sold_price
      membership.save
    end
  end
end
