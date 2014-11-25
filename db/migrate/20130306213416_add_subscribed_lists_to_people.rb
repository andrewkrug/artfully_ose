class AddSubscribedListsToPeople < ActiveRecord::Migration
  def change
    add_column :people, :subscribed_lists, :text
  end
end
