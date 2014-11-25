# This migration comes from artfully_ose_engine (originally 0)
class SetUpArtfully < ActiveRecord::Migration
  def change
    create_table "actions" do |t|
      t.integer  "organization_id"
      t.integer  "person_id"
      t.datetime "occurred_at"
      t.text     "details"
      t.boolean  "starred"
      t.integer  "dollar_amount"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "type"
      t.string   "subtype"
      t.integer  "subject_id"
      t.string   "subject_type"
      t.integer  "creator_id"
    end

    create_table "addresses" do |t|
      t.string   "address1"
      t.string   "address2"
      t.string   "city"
      t.string   "state"
      t.string   "zip"
      t.string   "country"
      t.integer  "person_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "addresses", ["person_id"], :name => "index_addresses_on_person_id"

    create_table "carts" do |t|
      t.string   "state"
      t.string   "transaction_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "type"
    end

    create_table "charts" do |t|
      t.string  "name"
      t.boolean "is_template"
      t.integer "event_id"
      t.integer "organization_id"
    end

    create_table "delayed_jobs" do |t|
      t.integer  "priority",   :default => 0
      t.integer  "attempts",   :default => 0
      t.text     "handler"
      t.text     "last_error"
      t.datetime "run_at"
      t.datetime "locked_at"
      t.datetime "failed_at"
      t.string   "locked_by"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "queue"
    end

    add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

    create_table "donations" do |t|
      t.integer  "amount"
      t.integer  "cart_id"
      t.integer  "organization_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "events" do |t|
      t.string   "name"
      t.string   "producer"
      t.boolean  "is_free"
      t.integer  "organization_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "deleted_at"
      t.string   "contact_phone"
      t.string   "contact_email"
      t.text     "description"
      t.integer  "venue_id"
      t.string   "image_file_name"
      t.string   "image_content_type"
      t.integer  "image_file_size"
      t.string   "special_instructions_caption", :default => "Special Instructions"
      t.boolean  "show_special_instructions",    :default => false
    end

    create_table "import_errors" do |t|
      t.integer  "import_id"
      t.text     "row_data"
      t.text     "error_message"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "import_rows" do |t|
      t.integer "import_id"
      t.text    "content"
    end

    create_table "imports" do |t|
      t.integer  "user_id"
      t.string   "s3_bucket"
      t.string   "s3_key"
      t.string   "s3_etag"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "status",          :default => "pending"
      t.text     "import_headers"
      t.integer  "organization_id"
    end

    create_table "items" do |t|
      t.string   "state"
      t.string   "product_type"
      t.integer  "product_id"
      t.integer  "price"
      t.integer  "realized_price"
      t.integer  "net"
      t.string   "fs_project_id"
      t.integer  "nongift_amount"
      t.boolean  "is_noncash"
      t.boolean  "is_stock"
      t.boolean  "is_anonymous"
      t.datetime "fs_available_on"
      t.datetime "reversed_at"
      t.string   "reversed_note"
      t.integer  "order_id"
      t.integer  "show_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "items", ["created_at"], :name => "index_items_on_created_at"
    add_index "items", ["order_id"], :name => "index_items_on_order_id"
    add_index "items", ["show_id"], :name => "index_items_on_show_id"

    create_table "kits" do |t|
      t.string   "state"
      t.string   "type"
      t.integer  "organization_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "memberships" do |t|
      t.integer "user_id"
      t.integer "organization_id"
    end

    create_table "notes" do |t|
      t.integer  "person_id"
      t.integer  "user_id"
      t.string   "type"
      t.text     "text"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "occurred_at"
      t.integer  "organization_id"
    end

    create_table "orders" do |t|
      t.string   "transaction_id"
      t.integer  "price"
      t.integer  "organization_id"
      t.integer  "person_id"
      t.integer  "parent_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "service_fee"
      t.string   "details"
      t.string   "type"
      t.string   "payment_method"
      t.text     "special_instructions"
    end

    add_index "orders", ["created_at"], :name => "index_orders_on_created_at"

    create_table "organizations" do |t|
      t.string   "name"
      t.string   "time_zone"
      t.string   "legal_organization_name"
      t.string   "ein"
      t.string   "website"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "lifetime_value",          :default => 0
    end

    create_table "people" do |t|
      t.integer  "organization_id"
      t.string   "state"
      t.string   "type"
      t.string   "email"
      t.string   "first_name"
      t.string   "last_name"
      t.string   "company_name"
      t.string   "website"
      t.boolean  "dummy"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "person_type"
      t.string   "twitter_handle"
      t.string   "facebook_url"
      t.string   "linked_in_url"
      t.integer  "import_id"
      t.datetime "deleted_at"
      t.integer  "lifetime_value",  :default => 0
    end

    add_index "people", ["organization_id", "email"], :name => "index_people_on_organization_id_and_email"
    add_index "people", ["organization_id"], :name => "index_people_on_organization_id"

    create_table "phones" do |t|
      t.string   "kind"
      t.string   "number"
      t.integer  "person_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "sections" do |t|
      t.text    "name"
      t.integer "capacity"
      t.integer "price"
      t.integer "chart_id"
      t.text    "description"
    end

    create_table "segments" do |t|
      t.string  "name"
      t.string  "terms"
      t.integer "organization_id"
    end
    
    create_table "shows" do |t|
      t.string   "state"
      t.datetime "datetime"
      t.integer  "event_id"
      t.integer  "chart_id"
      t.integer  "organization_id"
    end

    add_index "shows", ["event_id"], :name => "index_shows_on_event_id"
    add_index "shows", ["organization_id"], :name => "index_shows_on_organization_id"

    create_table "taggings" do |t|
      t.integer  "tag_id"
      t.integer  "taggable_id"
      t.string   "taggable_type"
      t.integer  "tagger_id"
      t.string   "tagger_type"
      t.string   "context"
      t.datetime "created_at"
    end

    add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
    add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

    create_table "tags" do |t|
      t.string "name"
    end

    create_table "tickets" do |t|
      t.string   "venue"
      t.string   "state"
      t.integer  "price"
      t.integer  "sold_price"
      t.datetime "sold_at"
      t.integer  "buyer_id"
      t.integer  "show_id"
      t.integer  "organization_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "cart_id"
      t.integer  "section_id"
    end

    add_index "tickets", ["cart_id"], :name => "index_tickets_on_cart_id"
    add_index "tickets", ["organization_id"], :name => "index_tickets_on_organization_id"
    add_index "tickets", ["section_id", "show_id", "state"], :name => "index_tickets_on_section_id_and_show_id_and_state"
    add_index "tickets", ["show_id"], :name => "index_tickets_on_show_id"
    add_index "tickets", ["state"], :name => "index_tickets_on_state"

    create_table "users" do |t|
      t.string   "email",                                 :default => "",   :null => false
      t.string   "encrypted_password",     :limit => 128, :default => ""
      t.string   "reset_password_token"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",                         :default => 0
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip"
      t.string   "last_sign_in_ip"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "customer_id"
      t.datetime "suspended_at"
      t.string   "suspension_reason"
      t.string   "invitation_token",       :limit => 60
      t.datetime "invitation_sent_at"
      t.integer  "invited_by_id"
      t.string   "invited_by_type"
      t.boolean  "newsletter_emails",                     :default => true, :null => false
      t.string   "mailchimp_message"
      t.datetime "reset_password_sent_at"
    end

    add_index "users", ["email"], :name => "index_users_on_email", :unique => true
    add_index "users", ["invitation_token"], :name => "index_users_on_invitation_token"
    add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

    create_table "venues" do |t|
      t.integer "organization_id"
      t.string  "name"
      t.string  "address1"
      t.string  "address2"
      t.string  "city"
      t.string  "state"
      t.string  "zip"
      t.string  "country"
      t.string  "time_zone"
      t.string  "phone"
      t.float   "lat"
      t.float   "long"
    end
  end
end
