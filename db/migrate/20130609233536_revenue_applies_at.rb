class RevenueAppliesAt < ActiveRecord::Migration
  def change
    add_column :orders, :revenue_applies_at, :datetime, :default => Time.now, :null => false

    execute "update orders set revenue_applies_at=created_at"

    ExchangeOrder.find_each do |order|
      order.update_column(:revenue_applies_at, order.originally_sold_at)
    end
  end
end
