class AddWelcomeMessageToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :welcome_message, :text, :default => nil
  end
end
