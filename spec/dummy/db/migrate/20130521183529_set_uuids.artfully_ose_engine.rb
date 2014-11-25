# This migration comes from artfully_ose_engine (originally 20121212023203)
class SetUuids < ActiveRecord::Migration
  def change
    Event.all.each do |event|
      event.update_column(:uuid, Ext::Uuid.uuid)
    end
    
    Show.all.each do |show|
      show.update_column(:uuid, Ext::Uuid.uuid)
    end
  end
end
