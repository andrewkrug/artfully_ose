class MakeEventsPublic < ActiveRecord::Migration
  def change
    execute "update events set public=1"
  end
end
