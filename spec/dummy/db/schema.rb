# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130712145604) do

  create_table "actions", :force => true do |t|
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
    t.integer  "import_id"
    t.datetime "deleted_at"
  end

  add_index "actions", ["creator_id"], :name => "index_actions_on_creator_id"
  add_index "actions", ["import_id"], :name => "index_actions_on_import_id"
  add_index "actions", ["organization_id", "person_id"], :name => "index_actions_on_organization_id_and_person_id"
  add_index "actions", ["organization_id"], :name => "index_actions_on_organization_id"
  add_index "actions", ["person_id"], :name => "index_actions_on_person_id"

  create_table "addresses", :force => true do |t|
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

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "username"
    t.string   "action"
    t.text     "audited_changes"
    t.integer  "version",         :default => 0
    t.string   "comment"
    t.string   "remote_address"
    t.datetime "created_at"
  end

  add_index "audits", ["associated_id", "associated_type"], :name => "associated_index"
  add_index "audits", ["auditable_id", "auditable_type"], :name => "auditable_index"
  add_index "audits", ["created_at"], :name => "index_audits_on_created_at"
  add_index "audits", ["user_id", "user_type"], :name => "user_index"

  create_table "carts", :force => true do |t|
    t.string   "state"
    t.string   "transaction_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.integer  "discount_id"
    t.string   "token"
    t.string   "reseller_id"
  end

  add_index "carts", ["token"], :name => "index_carts_on_token", :unique => true

  create_table "charts", :force => true do |t|
    t.string  "name"
    t.boolean "is_template"
    t.integer "event_id"
    t.integer "organization_id"
  end

  create_table "delayed_jobs", :force => true do |t|
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

  create_table "discounts", :force => true do |t|
    t.string   "code",                                   :null => false
    t.boolean  "active",               :default => true, :null => false
    t.string   "promotion_type",                         :null => false
    t.text     "properties"
    t.integer  "event_id",                               :null => false
    t.integer  "organization_id",                        :null => false
    t.integer  "user_id",                                :null => false
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.datetime "deleted_at"
    t.integer  "minimum_ticket_count"
    t.text     "sections"
    t.integer  "limit"
    t.text     "ticket_types"
  end

  create_table "discounts_shows", :force => true do |t|
    t.integer "discount_id", :null => false
    t.integer "show_id",     :null => false
  end

  create_table "donations", :force => true do |t|
    t.integer  "amount"
    t.integer  "cart_id"
    t.integer  "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "events", :force => true do |t|
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
    t.integer  "import_id"
    t.string   "uuid"
    t.string   "primary_category"
    t.text     "secondary_categories"
  end

  add_index "events", ["uuid"], :name => "index_events_on_uuid"
  add_index "events", ["venue_id"], :name => "index_events_on_venue_id"

  create_table "gateway_transactions", :force => true do |t|
    t.string   "transaction_id"
    t.boolean  "success"
    t.integer  "service_fee"
    t.integer  "amount"
    t.string   "message"
    t.text     "response"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "gateway_transactions", ["transaction_id"], :name => "index_gateway_transactions_on_transaction_id"

  create_table "import_errors", :force => true do |t|
    t.integer  "import_id"
    t.text     "row_data"
    t.text     "error_message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "import_messages", :force => true do |t|
    t.integer  "import_id"
    t.integer  "person_id"
    t.integer  "row_number"
    t.text     "row_data"
    t.text     "message"
    t.datetime "deleted_at"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "import_messages", ["import_id"], :name => "index_import_messages_on_import_id"

  create_table "import_rows", :force => true do |t|
    t.integer "import_id"
    t.text    "content"
  end

  add_index "import_rows", ["import_id"], :name => "index_import_rows_on_import_id"

  create_table "imports", :force => true do |t|
    t.integer  "user_id"
    t.string   "s3_bucket"
    t.string   "s3_key"
    t.string   "s3_etag"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",          :default => "pending"
    t.text     "import_headers"
    t.integer  "organization_id"
    t.string   "type"
  end

  create_table "items", :force => true do |t|
    t.string   "state"
    t.string   "product_type"
    t.integer  "product_id"
    t.integer  "price"
    t.integer  "realized_price"
    t.integer  "net"
    t.string   "fs_project_id"
    t.integer  "nongift_amount",  :default => 0
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
    t.datetime "deleted_at"
    t.integer  "discount_id"
    t.integer  "original_price"
  end

  add_index "items", ["created_at"], :name => "index_items_on_created_at"
  add_index "items", ["discount_id"], :name => "index_items_on_discount_id"
  add_index "items", ["order_id"], :name => "index_items_on_order_id"
  add_index "items", ["show_id"], :name => "index_items_on_show_id"

  create_table "items_view", :id => false, :force => true do |t|
    t.integer  "order_id",             :default => 0
    t.string   "order_type"
    t.integer  "item_id",              :default => 0, :null => false
    t.string   "product_type"
    t.integer  "organization_id",      :default => 0
    t.string   "organization_name"
    t.string   "time_zone"
    t.datetime "created_at"
    t.string   "payment_method"
    t.integer  "person_id",            :default => 0
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.datetime "datetime"
    t.integer  "show_id",              :default => 0
    t.integer  "event_id",             :default => 0
    t.string   "event_name"
    t.integer  "price"
    t.integer  "nongift_amount",       :default => 0
    t.text     "special_instructions"
    t.text     "notes"
  end

  create_table "kits", :force => true do |t|
    t.string   "state"
    t.string   "type"
    t.integer  "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "settings"
  end

  create_table "memberships", :force => true do |t|
    t.integer "user_id"
    t.integer "organization_id"
  end

  create_table "notes", :force => true do |t|
    t.integer  "person_id"
    t.integer  "user_id"
    t.string   "type"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "occurred_at"
    t.integer  "organization_id"
    t.boolean  "starred",         :default => false
  end

  add_index "notes", ["organization_id"], :name => "index_notes_on_organization_id"
  add_index "notes", ["person_id", "organization_id"], :name => "index_notes_on_person_id_and_organization_id"
  add_index "notes", ["person_id"], :name => "index_notes_on_person_id"
  add_index "notes", ["user_id"], :name => "index_notes_on_user_id"

  create_table "orders", :force => true do |t|
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
    t.integer  "import_id"
    t.datetime "deleted_at"
    t.text     "notes"
    t.datetime "revenue_applies_at",   :default => '2013-07-08 17:56:22', :null => false
  end

  add_index "orders", ["created_at"], :name => "index_orders_on_created_at"
  add_index "orders", ["person_id"], :name => "index_orders_on_person_id"
  add_index "orders", ["transaction_id"], :name => "index_orders_on_transaction_id"

  create_table "organizations", :force => true do |t|
    t.string   "name"
    t.string   "time_zone"
    t.string   "legal_organization_name"
    t.string   "ein"
    t.string   "website"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lifetime_value",             :default => 0
    t.string   "email"
    t.boolean  "receive_daily_sales_report", :default => true, :null => false
  end

  create_table "people", :force => true do |t|
    t.integer  "organization_id"
    t.string   "state"
    t.string   "type",               :default => "Individual", :null => false
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "company_name"
    t.string   "website"
    t.boolean  "dummy",              :default => false,        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subtype",            :default => "Individual", :null => false
    t.string   "twitter_handle"
    t.string   "facebook_url"
    t.string   "linked_in_url"
    t.integer  "import_id"
    t.datetime "deleted_at"
    t.integer  "lifetime_value",     :default => 0
    t.boolean  "do_not_email",       :default => false
    t.string   "salutation"
    t.string   "title"
    t.text     "subscribed_lists"
    t.integer  "lifetime_donations", :default => 0
    t.string   "middle_name"
    t.string   "suffix"
  end

  add_index "people", ["organization_id", "email"], :name => "index_people_on_organization_id_and_email"
  add_index "people", ["organization_id"], :name => "index_people_on_organization_id"

  create_table "phones", :force => true do |t|
    t.string   "kind"
    t.string   "number"
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "searches", :force => true do |t|
    t.integer  "organization_id",      :null => false
    t.string   "zip"
    t.string   "state"
    t.integer  "event_id"
    t.integer  "min_lifetime_value"
    t.integer  "min_donations_amount"
    t.integer  "max_lifetime_value"
    t.integer  "max_donations_amount"
    t.datetime "min_donations_date"
    t.datetime "max_donations_date"
    t.string   "tagging"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.string   "discount_code"
    t.string   "person_type"
    t.string   "person_subtype"
  end

  add_index "searches", ["organization_id"], :name => "index_searches_on_organization_id"

  create_table "sections", :force => true do |t|
    t.text    "name"
    t.integer "capacity"
    t.integer "chart_id"
    t.text    "description"
    t.boolean "storefront",  :default => true
    t.boolean "box_office",  :default => true
    t.boolean "members",     :default => true, :null => false
  end

  create_table "segments", :force => true do |t|
    t.string   "name",            :null => false
    t.integer  "organization_id", :null => false
    t.integer  "search_id",       :null => false
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "segments", ["organization_id"], :name => "index_segments_on_organization_id"
  add_index "segments", ["search_id"], :name => "index_segments_on_search_id"

  create_table "shows", :force => true do |t|
    t.string   "state"
    t.datetime "datetime"
    t.integer  "event_id"
    t.integer  "chart_id"
    t.integer  "organization_id"
    t.string   "uuid"
  end

  add_index "shows", ["event_id"], :name => "index_shows_on_event_id"
  add_index "shows", ["organization_id"], :name => "index_shows_on_organization_id"
  add_index "shows", ["uuid"], :name => "index_shows_on_uuid"

  create_table "taggings", :force => true do |t|
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

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "ticket_types", :force => true do |t|
    t.integer  "section_id",                    :null => false
    t.integer  "show_id"
    t.string   "name",                          :null => false
    t.integer  "price",                         :null => false
    t.integer  "limit"
    t.boolean  "storefront",  :default => true, :null => false
    t.boolean  "box_office",  :default => true, :null => false
    t.boolean  "members",     :default => true, :null => false
    t.text     "description"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "tickets", :force => true do |t|
    t.string   "venue"
    t.string   "state"
    t.integer  "sold_price"
    t.datetime "sold_at"
    t.integer  "buyer_id"
    t.integer  "show_id"
    t.integer  "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cart_id"
    t.integer  "section_id"
    t.integer  "cart_price"
    t.integer  "discount_id"
    t.integer  "ticket_type_id"
    t.boolean  "validated",           :default => false
    t.integer  "validated_action_id"
  end

  add_index "tickets", ["cart_id"], :name => "index_tickets_on_cart_id"
  add_index "tickets", ["discount_id"], :name => "index_tickets_on_discount_id"
  add_index "tickets", ["organization_id"], :name => "index_tickets_on_organization_id"
  add_index "tickets", ["section_id", "show_id", "state"], :name => "index_tickets_on_section_id_and_show_id_and_state"
  add_index "tickets", ["show_id"], :name => "index_tickets_on_show_id"
  add_index "tickets", ["state"], :name => "index_tickets_on_state"
  add_index "tickets", ["ticket_type_id"], :name => "index_tickets_on_ticket_type_id"

  create_table "users", :force => true do |t|
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

  create_table "venues", :force => true do |t|
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

  create_table "widget_requests", :force => true do |t|
    t.string   "request_uri",  :null => false
    t.string   "referer_host", :null => false
    t.string   "referer_uri",  :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "widget_requests", ["referer_host"], :name => "index_widget_requests_on_referer_host"

end
