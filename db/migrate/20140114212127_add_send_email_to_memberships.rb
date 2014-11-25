class AddSendEmailToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :send_email, :boolean, :default => true
  end
end
