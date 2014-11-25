class AddMarketingToMembershipType < ActiveRecord::Migration
  def change
    add_column :membership_types, :thanks_copy, :text, :default => nil
    add_column :membership_types, :invitation_email_text_copy, :text, :default => nil
  end
end
