class AddCheckNumberToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :check_number, :string
  end
end
