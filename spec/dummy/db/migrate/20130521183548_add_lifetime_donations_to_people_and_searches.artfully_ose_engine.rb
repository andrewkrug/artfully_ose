# This migration comes from artfully_ose_engine (originally 20130326173653)
#
# This should have originally been in the engine but somehow ended up in core
# This migration is named the same as the core migration so core skips it
#
class AddLifetimeDonationsToPeopleAndSearches < ActiveRecord::Migration
  def change
    add_column :people, :lifetime_donations, :integer, :default => 0
  end
end
