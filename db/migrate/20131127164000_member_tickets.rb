class MemberTickets < ActiveRecord::Migration
  def change
    add_column :ticket_types, :membership_type_id,      :integer, :default => nil
    add_column :ticket_types, :tickets_per_membership,  :integer, :default => nil
    add_column :ticket_types, :member_ticket,           :boolean, :default => false

    add_index :ticket_types, :membership_type_id
  end
end
