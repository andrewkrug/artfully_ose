# This migration comes from artfully_ose_engine (originally 20130412145428)
#
# Migrate received HearActions to the new SayAction
# Remove parenthesis from subtypes
#
class MassageActionSubtypes < ActiveRecord::Migration
  def change 
    execute "update actions set type='SayAction',  subtype='Email'   where type='HearAction' and subtype='Email (received)'"
    execute "update actions set type='SayAction',  subtype='Phone'   where type='HearAction' and subtype='Phone (received)'"
    execute "update actions set type='SayAction',  subtype='Postal'  where type='HearAction' and subtype='Postal (received)'"

    execute "update actions set                    subtype='Email'   where type='HearAction' and subtype='Email (sent)'"
    execute "update actions set                    subtype='Phone'   where type='HearAction' and subtype='Phone (initiated)'"
    execute "update actions set                    subtype='Postal'  where type='HearAction' and subtype='Postal (sent)'"
  end
end
