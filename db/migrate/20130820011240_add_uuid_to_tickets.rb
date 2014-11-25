class AddUuidToTickets < ActiveRecord::Migration
  def change
    add_column :tickets, :uuid, :string
    add_index :tickets, :uuid, :unique => true

    #
    # This is usually done in a rake task for speed, but local migrations can stand to do it inline
    #
    Ticket.unscoped.where(:uuid => nil).pluck(:id).each do |ticket_id|
      Ticket.unscoped.update_all({ :uuid => Ext::Uuid.uuid }, :id => ticket_id, :uuid => nil)
    end
  end
end
