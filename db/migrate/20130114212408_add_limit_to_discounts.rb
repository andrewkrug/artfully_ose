class AddLimitToDiscounts < ActiveRecord::Migration
  def change
    add_column :discounts, :limit, :integer
  end
end
