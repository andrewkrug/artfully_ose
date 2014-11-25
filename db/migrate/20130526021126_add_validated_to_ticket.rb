class AddValidatedToTicket < ActiveRecord::Migration
  def change
    add_column :tickets, :validated, :boolean, :default => false
  end
end
