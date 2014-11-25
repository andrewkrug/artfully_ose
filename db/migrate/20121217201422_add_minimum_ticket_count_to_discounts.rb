class AddMinimumTicketCountToDiscounts < ActiveRecord::Migration
  def change
    add_column :discounts, :minimum_ticket_count, :integer
  end
end
