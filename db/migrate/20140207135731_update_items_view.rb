class UpdateItemsView < ActiveRecord::Migration
  def up
    execute "CREATE OR REPLACE VIEW items_view as " +
              "select "  +
              "orders.id as order_id," +
              "orders.type as order_type," +
              "items.id as item_id," +
              "items.product_type as product_type," +
              "organizations.id as organization_id," +
              "organizations.name as organization_name," +
              "organizations.time_zone as time_zone," +
              "orders.created_at,"  +
              "orders.payment_method," + 
              # people and addresses got moved out into a relation
              # since this export now runs in a background job, speed isn't the primary concern
              "people.id as person_id," +
              "shows.datetime," +
              "shows.id as show_id," +
              "events.id as event_id," +
              "events.name as event_name," +
              "items.price," +
              "items.nongift_amount," +
              "orders.special_instructions, " +
              "orders.notes " +
              "from items " +
              "LEFT OUTER JOIN `orders` ON `orders`.`id` = `items`.`order_id`"  +              
              "LEFT OUTER JOIN `people` ON `people`.`id` = `orders`.`person_id` " +
              "LEFT OUTER JOIN `organizations` ON `organizations`.`id` = `orders`.`organization_id`" +
              "LEFT OUTER JOIN `shows` ON `shows`.`id` = `items`.`show_id` " +
              "LEFT OUTER JOIN `events` ON `events`.`id` = `shows`.`event_id` " +
              "LEFT OUTER JOIN `venues` ON `venues`.`id` = `events`.`venue_id`"  +
              "WHERE `items`.`deleted_at` IS NULL "
  end

  def down
    execute "drop view items_view"
  end
end
