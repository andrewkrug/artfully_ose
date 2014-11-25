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
