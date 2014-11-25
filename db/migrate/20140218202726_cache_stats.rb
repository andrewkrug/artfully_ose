class CacheStats < ActiveRecord::Migration
  def change
    Show.find_in_batches do |shows|
      shows.each {|s| s.delay.refresh_stats unless s.event.nil? }
    end
  end
end
