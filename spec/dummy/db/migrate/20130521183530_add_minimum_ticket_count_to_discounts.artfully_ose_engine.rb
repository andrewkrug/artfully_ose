# This migration comes from artfully_ose_engine (originally 20121217201422)
class AddMinimumTicketCountToDiscounts < ActiveRecord::Migration
  def change
    add_column :discounts, :minimum_ticket_count, :integer
  end
end
