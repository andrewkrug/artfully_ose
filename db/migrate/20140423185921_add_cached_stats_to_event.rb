class AddCachedStatsToEvent < ActiveRecord::Migration
  def change
    add_column :events, :cached_stats, :text

    Event.all.each do |event|
      event.delay.refresh_stats
    end
  end
end
