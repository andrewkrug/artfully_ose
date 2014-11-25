class CreateShowStatsView < ActiveRecord::Migration
  def change
    execute "CREATE OR REPLACE VIEW show_stats_view as select " + 
              "shows.id, shows.id as show_id, shows.event_id as event_id, shows.organization_id as organization_id, shows.datetime, shows.state as state, count(tickets.id) as capacity, venues.time_zone as time_zone,  " + 
              "SUM(CASE WHEN tickets.state='sold' then 1 else 0 end) as sold, " + 
              "SUM(CASE WHEN tickets.state='comped' then 1 else 0 end) as comped, " + 
              "SUM(CASE WHEN tickets.state='on_sale' then 1 else 0 end) as on_sale, " + 
              "SUM(CASE WHEN tickets.state='off_sale' then 1 else 0 end) as off_sale, " + 
              "SUM(CASE WHEN tickets.state='on_sale' or tickets.state='off_sale' then 1 else 0 end) as 'open' "  + 
              "from shows " + 
              "left join tickets on shows.id = tickets.show_id " + 
              "left join events on shows.event_id = events.id " + 
              "left join venues on events.venue_id = venues.id " +
              "group by shows.id"
  end
end