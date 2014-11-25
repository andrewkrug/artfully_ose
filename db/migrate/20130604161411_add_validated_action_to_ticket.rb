class AddValidatedActionToTicket < ActiveRecord::Migration
  def change
    add_column :tickets, :validated_action_id, :integer, :default => nil
  end
end
