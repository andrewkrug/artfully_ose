class AddDiscountCodeToSearch < ActiveRecord::Migration
  def change
    add_column :searches, :discount_code, :string
  end
end
