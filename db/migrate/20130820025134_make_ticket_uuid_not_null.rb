class MakeTicketUuidNotNull < ActiveRecord::Migration
  def up
    # Every ticket must have a uuid for this to work.
    # Run `rake backfill_ticket_uuids` first
    change_column_null :tickets, :uuid, false
  end

  def down
    change_column_null :tickets, :uuid, true
  end
end
