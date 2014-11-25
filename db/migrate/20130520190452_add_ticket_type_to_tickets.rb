class AddTicketTypeToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :ticket_type_id, :integer
    add_index  :tickets, :ticket_type_id
  end
end