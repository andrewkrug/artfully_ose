class AddTicketTypesToDiscounts < ActiveRecord::Migration
  def change
    add_column :discounts, :ticket_types, :text
  end
end
