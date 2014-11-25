# This migration comes from artfully_ose_engine (originally 20130306213416)
class AddSubscribedListsToPeople < ActiveRecord::Migration
  def change
    add_column :people, :subscribed_lists, :text
  end
end
