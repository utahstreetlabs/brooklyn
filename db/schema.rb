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

ActiveRecord::Schema.define(:version => 20130502183159) do

  create_table "annotations", :force => true do |t|
    t.string   "url"
    t.integer  "creator_id"
    t.integer  "annotatable_id"
    t.string   "annotatable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "annotations", ["creator_id"], :name => "index_annotations_on_creator_id"

  create_table "api_configs", :force => true do |t|
    t.integer  "user_id",                     :null => false
    t.string   "token",        :limit => 128, :null => false
    t.string   "format",       :limit => 128
    t.string   "callback_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "api_configs", ["token"], :name => "index_api_configs_on_token", :unique => true
  add_index "api_configs", ["user_id"], :name => "api_configs_user_id_fk"

  create_table "blocks", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "blocker_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "blocks", ["blocker_id", "user_id"], :name => "index_blocker_id_and_user_id", :unique => true
  add_index "blocks", ["blocker_id"], :name => "blocker_id"
  add_index "blocks", ["user_id"], :name => "user_id"

  create_table "cancelled_orders", :force => true do |t|
    t.integer  "listing_id",                                                   :null => false
    t.string   "uuid",                       :limit => 64
    t.integer  "shipping_address_id"
    t.string   "payment_sid"
    t.boolean  "bill_to_shipping",                           :default => true
    t.datetime "confirmed_at"
    t.datetime "shipped_at"
    t.datetime "delivery_status_checked_at"
    t.datetime "delivered_at"
    t.datetime "completed_at"
    t.datetime "canceled_at"
    t.datetime "return_shipped_at"
    t.datetime "return_delivered_at"
    t.datetime "return_completed_at"
    t.string   "carrier"
    t.string   "tracking_number"
    t.string   "reference_number",                                             :null => false
    t.datetime "staged_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "buyer_id"
    t.string   "previous_status"
    t.boolean  "private",                                    :default => true, :null => false
    t.integer  "billing_address_id"
    t.string   "balanced_debit_url",         :limit => 1000
    t.string   "balanced_credit_url",        :limit => 1000
    t.string   "balanced_refund_url",        :limit => 1000
    t.datetime "settled_at"
  end

  add_index "cancelled_orders", ["billing_address_id"], :name => "index_cancelled_orders_on_billing_address_id"
  add_index "cancelled_orders", ["buyer_id"], :name => "index_cancelled_orders_on_buyer_id"
  add_index "cancelled_orders", ["listing_id"], :name => "index_cancelled_orders_on_listing_id"
  add_index "cancelled_orders", ["payment_sid"], :name => "index_cancelled_orders_on_payment_sid"
  add_index "cancelled_orders", ["reference_number"], :name => "index_cancelled_orders_on_reference_number", :unique => true
  add_index "cancelled_orders", ["shipping_address_id"], :name => "index_cancelled_orders_on_shipping_address_id"
  add_index "cancelled_orders", ["uuid"], :name => "index_cancelled_orders_on_uuid", :unique => true

  create_table "categories", :force => true do |t|
    t.string   "name",       :limit => 128, :null => false
    t.string   "slug",       :limit => 128, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "categories", ["name"], :name => "index_categories_on_name", :unique => true
  add_index "categories", ["slug"], :name => "index_categories_on_slug", :unique => true

  create_table "collection_autofollows", :force => true do |t|
    t.integer  "collection_id", :null => false
    t.integer  "interest_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "collection_autofollows", ["collection_id"], :name => "collection_autofollows_collection_id_fk"
  add_index "collection_autofollows", ["interest_id"], :name => "collection_autofollows_interest_id_fk"

  create_table "collection_follows", :force => true do |t|
    t.integer  "user_id",       :null => false
    t.integer  "collection_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "collection_follows", ["collection_id"], :name => "collection_follows_collection_id_fk"
  add_index "collection_follows", ["user_id", "collection_id"], :name => "index_collection_follows_on_user_id_and_collection_id", :unique => true

  create_table "collections", :force => true do |t|
    t.integer  "user_id",                                        :null => false
    t.string   "name",           :limit => 50,                   :null => false
    t.string   "slug",           :limit => 50,                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "editable",                     :default => true
    t.integer  "type_code",      :limit => 2,  :default => 1,    :null => false
    t.integer  "listing_count",                :default => 0
    t.integer  "follower_count",               :default => 0
  end

  add_index "collections", ["user_id", "slug"], :name => "index_collections_on_user_id_and_slug", :unique => true

  create_table "contacts", :force => true do |t|
    t.integer  "email_account_id",                :null => false
    t.integer  "person_id",                       :null => false
    t.string   "fullname"
    t.string   "firstname",        :limit => 128
    t.string   "lastname"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contacts", ["email_account_id"], :name => "contacts_email_account_id_fk"
  add_index "contacts", ["person_id"], :name => "contacts_person_id_fk"

  create_table "credits", :force => true do |t|
    t.decimal  "amount",                   :precision => 18, :scale => 2
    t.datetime "expires_at"
    t.integer  "offer_id"
    t.string   "offer_uuid", :limit => 64
    t.string   "trigger_id"
    t.integer  "user_id",                                                 :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "credits", ["offer_id"], :name => "credits_offer_id_fk"
  add_index "credits", ["offer_uuid"], :name => "index_credits_on_offer_id"
  add_index "credits", ["user_id"], :name => "index_credits_on_user_id"

  create_table "debits", :force => true do |t|
    t.integer  "credit_id"
    t.integer  "order_id"
    t.decimal  "amount",     :precision => 18, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "debits", ["credit_id"], :name => "debits_credit_id_fk"
  add_index "debits", ["order_id"], :name => "debits_order_id_fk"

  create_table "deposit_accounts", :force => true do |t|
    t.integer  "user_id",                                         :null => false
    t.boolean  "default",                      :default => false, :null => false
    t.string   "type",         :limit => 50
    t.string   "name",         :limit => 64
    t.string   "balanced_url", :limit => 1000
    t.string   "last_four",    :limit => 4
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deposit_accounts", ["user_id"], :name => "deposit_accounts_user_id_fk"

  create_table "dimension_value_listing_attachments", :force => true do |t|
    t.integer  "listing_id",         :null => false
    t.integer  "dimension_value_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dimension_value_listing_attachments", ["dimension_value_id"], :name => "dimension_value_listing_attachments_dimension_value_id_fk"
  add_index "dimension_value_listing_attachments", ["listing_id", "dimension_value_id"], :name => "index_dv_listing_attachments_on_listing_id_and_dv_id", :unique => true

  create_table "dimension_values", :force => true do |t|
    t.integer  "dimension_id",               :null => false
    t.string   "value",        :limit => 64, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
  end

  add_index "dimension_values", ["dimension_id", "value"], :name => "index_dimension_values_on_dimension_id_and_value", :unique => true

  create_table "dimensions", :force => true do |t|
    t.integer  "category_id",                :null => false
    t.string   "name",        :limit => 128, :null => false
    t.string   "slug",        :limit => 128, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dimensions", ["category_id", "name"], :name => "index_dimensions_on_category_id_and_name", :unique => true
  add_index "dimensions", ["category_id", "slug"], :name => "index_dimensions_on_category_id_and_slug", :unique => true

  create_table "dislikes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "listing_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dislikes", ["listing_id"], :name => "dislikes_listing_id_fk"
  add_index "dislikes", ["user_id"], :name => "dislikes_user_id_fk"

  create_table "email_accounts", :force => true do |t|
    t.integer  "user_id",                  :null => false
    t.string   "provider",   :limit => 64
    t.string   "email"
    t.string   "identifier"
    t.string   "sync_state", :limit => 32
    t.datetime "synced_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_accounts", ["email"], :name => "index_email_accounts_on_email", :unique => true
  add_index "email_accounts", ["identifier"], :name => "index_email_accounts_on_identifier", :unique => true
  add_index "email_accounts", ["user_id"], :name => "email_accounts_user_id_fk"

  create_table "facebook_u2u_invites", :force => true do |t|
    t.integer  "facebook_u2u_request_id",               :null => false
    t.integer  "user_id"
    t.string   "fb_user_id",                            :null => false
    t.string   "invite_code",                           :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source",                  :limit => 20
  end

  add_index "facebook_u2u_invites", ["facebook_u2u_request_id"], :name => "index_facebook_u2u_invites_on_facebook_u2u_request_id"
  add_index "facebook_u2u_invites", ["fb_user_id"], :name => "index_facebook_u2u_invites_on_fb_user_id"
  add_index "facebook_u2u_invites", ["user_id"], :name => "index_facebook_u2u_invites_on_user_id"

  create_table "facebook_u2u_requests", :force => true do |t|
    t.integer  "user_id",       :null => false
    t.string   "fb_request_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "facebook_u2u_requests", ["fb_request_id"], :name => "index_facebook_u2u_requests_on_fb_request_id"
  add_index "facebook_u2u_requests", ["user_id"], :name => "index_facebook_u2u_requests_on_user_id"

  create_table "feature_flags", :force => true do |t|
    t.string   "name",                             :null => false
    t.string   "description",                      :null => false
    t.boolean  "enabled",       :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin_enabled", :default => false, :null => false
  end

  add_index "feature_flags", ["name"], :name => "index_feature_flags_on_name", :unique => true

  create_table "feature_lists", :force => true do |t|
    t.string   "name",       :limit => 128, :null => false
    t.string   "slug",       :limit => 128, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "feature_lists", ["name"], :name => "index_feature_lists_on_name", :unique => true
  add_index "feature_lists", ["slug"], :name => "index_feature_lists_on_slug", :unique => true

  create_table "follow_tombstones", :force => true do |t|
    t.integer  "user_id",     :null => false
    t.integer  "follower_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "follow_tombstones", ["follower_id", "user_id"], :name => "index_follow_tombstones_on_follower_id_and_user_id", :unique => true
  add_index "follow_tombstones", ["user_id"], :name => "follow_tombstones_user_id_fk"

  create_table "follows", :force => true do |t|
    t.integer  "user_id",                          :null => false
    t.integer  "follower_id",                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "fb_subscription_id", :limit => 32
    t.integer  "follow_type",        :limit => 1
  end

  add_index "follows", ["follower_id", "created_at"], :name => "index_follows_on_follower_id_and_created_at"
  add_index "follows", ["follower_id", "user_id"], :name => "index_follower_id_and_user_id", :unique => true
  add_index "follows", ["follower_id"], :name => "follower_id"
  add_index "follows", ["user_id", "created_at"], :name => "index_follows_on_user_id_and_created_at"
  add_index "follows", ["user_id", "follow_type"], :name => "index_follows_on_user_id_and_follow_type"
  add_index "follows", ["user_id"], :name => "user_id"

  create_table "haves", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "item_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "haves", ["item_id"], :name => "haves_item_id_fk"
  add_index "haves", ["user_id", "item_id"], :name => "index_haves_on_user_id_and_item_id", :unique => true

  create_table "interests", :force => true do |t|
    t.string   "name",                           :null => false
    t.boolean  "onboarding",  :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cover_photo"
    t.integer  "position"
    t.boolean  "gender"
  end

  add_index "interests", ["gender"], :name => "index_interests_on_gender"
  add_index "interests", ["name"], :name => "index_interests_on_name", :unique => true

  create_table "invite_acceptances", :force => true do |t|
    t.integer  "user_id",                                   :null => false
    t.string   "invite_uuid",                               :null => false
    t.boolean  "credited",               :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "inviter_id"
    t.integer  "facebook_u2u_invite_id"
  end

  add_index "invite_acceptances", ["facebook_u2u_invite_id"], :name => "index_invite_acceptances_on_facebook_u2u_invite_id"
  add_index "invite_acceptances", ["invite_uuid", "credited"], :name => "index_invite_acceptances_on_invite_uuid_and_credited"
  add_index "invite_acceptances", ["inviter_id", "credited"], :name => "index_invite_acceptances_on_inviter_id_and_credited"
  add_index "invite_acceptances", ["user_id"], :name => "invite_acceptances_user_id_fk"

  create_table "items", :force => true do |t|
    t.integer  "product_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "items", ["product_id"], :name => "product_id"

  create_table "listing_collection_attachments", :force => true do |t|
    t.integer  "collection_id", :null => false
    t.integer  "listing_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "listing_collection_attachments", ["collection_id"], :name => "listing_collection_attachments_collection_id_fk"
  add_index "listing_collection_attachments", ["listing_id", "collection_id"], :name => "index_lca_on_listing_id_and_collection_id", :unique => true

  create_table "listing_features", :force => true do |t|
    t.integer  "featurable_id",                  :null => false
    t.string   "featurable_type",                :null => false
    t.integer  "listing_id",                     :null => false
    t.integer  "position",        :default => 1, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "listing_features", ["featurable_id"], :name => "index_listing_features_on_featurable_id"
  add_index "listing_features", ["listing_id"], :name => "index_listing_features_on_listing_id"

  create_table "listing_flags", :force => true do |t|
    t.integer  "listing_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "listing_flags", ["listing_id"], :name => "listing_flags_listing_id_fk"
  add_index "listing_flags", ["user_id"], :name => "listing_flags_user_id_fk"

  create_table "listing_offers", :force => true do |t|
    t.integer  "listing_id",                                :null => false
    t.integer  "user_id",                                   :null => false
    t.decimal  "amount",     :precision => 18, :scale => 2, :null => false
    t.integer  "duration",                                  :null => false
    t.string   "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "listing_offers", ["listing_id"], :name => "listing_offers_listing_id_fk"
  add_index "listing_offers", ["user_id"], :name => "listing_offers_user_id_fk"

  create_table "listing_photos", :force => true do |t|
    t.string   "uuid",       :limit => 128
    t.integer  "listing_id",                :null => false
    t.string   "file",                      :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.string   "source_uid", :limit => 128
    t.integer  "height"
    t.integer  "width"
  end

  add_index "listing_photos", ["listing_id", "source_uid"], :name => "index_listing_photos_on_listing_id_and_source_uid", :unique => true
  add_index "listing_photos", ["listing_id"], :name => "listing_photos_listing_id_fk"
  add_index "listing_photos", ["uuid"], :name => "index_listing_photos_on_uuid", :unique => true

  create_table "listing_source_images", :force => true do |t|
    t.integer  "listing_source_id", :null => false
    t.string   "url",               :null => false
    t.integer  "height"
    t.integer  "width"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "size"
  end

  add_index "listing_source_images", ["listing_source_id"], :name => "index_listing_source_images_on_listing_source_id"

  create_table "listing_sources", :force => true do |t|
    t.string   "uuid",       :limit => 36,                                  :null => false
    t.string   "url",        :limit => 1000,                                :null => false
    t.string   "title",      :limit => 80
    t.decimal  "price",                      :precision => 18, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "listing_sources", ["url"], :name => "index_listing_sources_on_url", :length => {"url"=>255}
  add_index "listing_sources", ["uuid"], :name => "index_listing_sources_on_uuid", :unique => true

  create_table "listing_tag_attachments", :force => true do |t|
    t.integer  "listing_id", :null => false
    t.integer  "tag_id",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "listing_tag_attachments", ["listing_id", "tag_id"], :name => "index_listing_tag_attachments_on_listing_id_and_tag_id", :unique => true
  add_index "listing_tag_attachments", ["tag_id"], :name => "listing_tag_attachments_tag_id_fk"

  create_table "listings", :force => true do |t|
    t.string   "uuid",                        :limit => 64
    t.integer  "item_id"
    t.string   "title"
    t.text     "description"
    t.decimal  "price",                                      :precision => 18, :scale => 2
    t.decimal  "shipping",                                   :precision => 18, :scale => 2
    t.decimal  "tax",                                        :precision => 18, :scale => 2
    t.decimal  "original_price",                             :precision => 18, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "category_id"
    t.integer  "seller_id",                                                                                                :null => false
    t.string   "state",                       :limit => 32,                                 :default => "pending",         :null => false
    t.integer  "buyer_id"
    t.string   "slug",                                                                                                     :null => false
    t.integer  "pricing_version",                                                                                          :null => false
    t.string   "source_uid",                  :limit => 128
    t.boolean  "seller_pays_marketplace_fee",                                               :default => false
    t.datetime "featured_at"
    t.integer  "handling_duration",                                                         :default => 345600
    t.integer  "size_id"
    t.integer  "brand_id"
    t.boolean  "approved"
    t.datetime "activated_at"
    t.datetime "suspended_at"
    t.datetime "cancelled_at"
    t.datetime "sold_at"
    t.datetime "approved_at"
    t.boolean  "has_been_activated"
    t.string   "type",                                                                      :default => "InternalListing", :null => false
    t.integer  "listing_source_id"
  end

  add_index "listings", ["brand_id"], :name => "listings_brand_id_fk"
  add_index "listings", ["buyer_id"], :name => "index_listings_on_buyer_id"
  add_index "listings", ["category_id"], :name => "listings_category_id_fk"
  add_index "listings", ["item_id"], :name => "item_id"
  add_index "listings", ["listing_source_id"], :name => "listings_listing_source_id_fk"
  add_index "listings", ["seller_id", "source_uid"], :name => "index_listings_on_seller_id_and_source_uid", :unique => true
  add_index "listings", ["seller_id"], :name => "index_listings_on_seller_id"
  add_index "listings", ["size_id"], :name => "listings_size_id_fk"
  add_index "listings", ["slug"], :name => "index_listings_on_slug", :unique => true
  add_index "listings", ["state", "seller_id"], :name => "index_listings_on_state_and_seller_id"
  add_index "listings", ["state"], :name => "index_listings_on_state"
  add_index "listings", ["uuid"], :name => "index_listings_on_uuid", :unique => true

  create_table "offers", :force => true do |t|
    t.string   "uuid",                          :limit => 64,                                                   :null => false
    t.string   "name"
    t.string   "destination_url"
    t.string   "info_url"
    t.decimal  "amount",                                      :precision => 18, :scale => 2,                    :null => false
    t.decimal  "minimum_purchase",                            :precision => 18, :scale => 2, :default => 0.0,   :null => false
    t.integer  "duration",                                                                                      :null => false
    t.integer  "available",                                                                                     :null => false
    t.boolean  "new_users",                                                                  :default => false, :null => false
    t.boolean  "existing_users",                                                             :default => false, :null => false
    t.boolean  "signup",                                                                     :default => false, :null => false
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ab_tag"
    t.string   "descriptor",                                                                                    :null => false
    t.string   "landing_page_headline"
    t.text     "landing_page_text"
    t.string   "landing_page_background_photo"
    t.string   "fb_story_name"
    t.string   "fb_story_caption"
    t.text     "fb_story_description"
    t.string   "fb_story_image"
    t.boolean  "no_purchase_users",                                                          :default => false
    t.boolean  "no_credit_users",                                                            :default => false
  end

  add_index "offers", ["ab_tag"], :name => "index_offers_on_ab_tag", :unique => true

  create_table "order_ratings", :force => true do |t|
    t.string   "type",                            :null => false
    t.integer  "order_id"
    t.integer  "user_id",                         :null => false
    t.boolean  "flag"
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "cancelled_order_id"
    t.datetime "purchased_at"
    t.integer  "failure_reason",     :limit => 2
  end

  add_index "order_ratings", ["cancelled_order_id"], :name => "order_ratings_cancelled_order_id_fk"
  add_index "order_ratings", ["order_id", "user_id"], :name => "index_order_ratings_on_order_id_and_user_id", :unique => true
  add_index "order_ratings", ["order_id"], :name => "index_order_ratings_on_order_id"
  add_index "order_ratings", ["user_id"], :name => "index_order_ratings_on_user_id"

  create_table "orders", :force => true do |t|
    t.string   "uuid",                                 :limit => 64
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "listing_id",                                                                  :null => false
    t.integer  "shipping_address_id"
    t.string   "payment_sid"
    t.string   "status",                               :limit => 32,   :default => "pending", :null => false
    t.boolean  "bill_to_shipping",                                     :default => true
    t.datetime "confirmed_at"
    t.datetime "completed_at"
    t.datetime "canceled_at"
    t.datetime "return_completed_at"
    t.string   "reference_number",                                                            :null => false
    t.datetime "staged_at"
    t.integer  "buyer_id"
    t.boolean  "private",                                              :default => true,      :null => false
    t.string   "balanced_debit_url",                   :limit => 1000
    t.integer  "billing_address_id"
    t.string   "balanced_credit_url",                  :limit => 1000
    t.string   "balanced_refund_url",                  :limit => 1000
    t.datetime "settled_at"
    t.datetime "delivery_confirmation_requested_at"
    t.datetime "delivery_confirmation_followed_up_at"
  end

  add_index "orders", ["billing_address_id"], :name => "index_orders_on_billing_address_id"
  add_index "orders", ["buyer_id"], :name => "index_orders_on_buyer_id"
  add_index "orders", ["confirmed_at"], :name => "index_orders_on_confirmed_at"
  add_index "orders", ["listing_id"], :name => "index_orders_on_listing_id", :unique => true
  add_index "orders", ["payment_sid"], :name => "index_orders_on_payment_sid"
  add_index "orders", ["reference_number"], :name => "index_orders_on_reference_number", :unique => true
  add_index "orders", ["shipping_address_id"], :name => "index_orders_on_shipping_address_id"
  add_index "orders", ["status"], :name => "index_orders_on_status"
  add_index "orders", ["uuid"], :name => "index_orders_on_uuid", :unique => true

  create_table "paypal_payments", :force => true do |t|
    t.integer  "order_id",                                                                               :null => false
    t.integer  "deposit_account_id",                                                                     :null => false
    t.decimal  "amount",                           :precision => 18, :scale => 2,                        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",              :limit => 32,                                :default => "pending", :null => false
    t.datetime "paid_at"
  end

  add_index "paypal_payments", ["deposit_account_id"], :name => "paypal_payments_deposit_account_id_fk"
  add_index "paypal_payments", ["order_id"], :name => "paypal_payments_order_id_fk"

  create_table "people", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "postal_addresses", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",                               :null => false
    t.string   "ref_type",                              :null => false
    t.string   "line1",                                 :null => false
    t.string   "line2"
    t.string   "city",                                  :null => false
    t.string   "state",                                 :null => false
    t.string   "zip",                                   :null => false
    t.string   "phone",                                 :null => false
    t.string   "name",                                  :null => false
    t.boolean  "default_address",    :default => false
    t.integer  "order_id"
    t.integer  "cancelled_order_id"
    t.integer  "listing_id"
  end

  add_index "postal_addresses", ["cancelled_order_id"], :name => "postal_addresses_cancelled_order_id_fk"
  add_index "postal_addresses", ["listing_id"], :name => "postal_addresses_listing_id_fk"
  add_index "postal_addresses", ["order_id"], :name => "postal_addresses_order_id_fk"
  add_index "postal_addresses", ["ref_type"], :name => "index_postal_addresses_on_ref_type"
  add_index "postal_addresses", ["user_id", "name", "line1", "order_id", "cancelled_order_id"], :name => "index_postal_addresses_on_user_id_line1_name_order_ids", :unique => true
  add_index "postal_addresses", ["user_id"], :name => "index_postal_addresses_on_user_id"

  create_table "price_alerts", :force => true do |t|
    t.integer  "listing_id",                             :null => false
    t.integer  "user_id",                                :null => false
    t.integer  "threshold",  :limit => 3, :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "price_alerts", ["listing_id"], :name => "price_alerts_listing_id_fk"
  add_index "price_alerts", ["user_id", "listing_id"], :name => "index_price_alerts_on_user_id_and_listing_id", :unique => true

  create_table "secret_seller_items", :force => true do |t|
    t.integer  "seller_id",                                                :null => false
    t.string   "title",       :limit => 80,                                :null => false
    t.text     "description",                                              :null => false
    t.decimal  "price",                     :precision => 18, :scale => 2, :null => false
    t.string   "condition",                                                :null => false
    t.string   "photo",                                                    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "secret_seller_items", ["seller_id"], :name => "secret_seller_items_seller_id_fk"

  create_table "seller_offers", :force => true do |t|
    t.integer  "seller_id",  :null => false
    t.integer  "offer_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "seller_offers", ["offer_id"], :name => "seller_offers_offer_id_fk"
  add_index "seller_offers", ["seller_id"], :name => "seller_offers_seller_id_fk"

  create_table "seller_payments", :force => true do |t|
    t.integer  "order_id",                                                                               :null => false
    t.integer  "deposit_account_id",                                                                     :null => false
    t.decimal  "amount",                           :precision => 18, :scale => 2,                        :null => false
    t.string   "state",              :limit => 32,                                :default => "pending", :null => false
    t.string   "type",               :limit => 50,                                                       :null => false
    t.datetime "paid_at"
    t.datetime "rejected_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "canceled_at"
  end

  add_index "seller_payments", ["deposit_account_id"], :name => "seller_payments_deposit_account_id_fk"
  add_index "seller_payments", ["order_id"], :name => "seller_payments_order_id_fk"
  add_index "seller_payments", ["type", "state"], :name => "index_seller_payments_on_type_and_state"

  create_table "shipments", :force => true do |t|
    t.integer  "order_id",                                                    :null => false
    t.boolean  "return",                                   :default => false
    t.string   "carrier_name",               :limit => 16,                    :null => false
    t.string   "tracking_number",            :limit => 64,                    :null => false
    t.datetime "delivery_status_checked_at"
    t.datetime "delivered_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "shipment_status_checked_at"
    t.datetime "shipped_at"
  end

  add_index "shipments", ["order_id", "return"], :name => "index_shipments_on_order_id_and_return", :unique => true
  add_index "shipments", ["shipment_status_checked_at"], :name => "index_shipments_on_shipment_status_checked_at"

  create_table "shipping_labels", :force => true do |t|
    t.integer  "order_id"
    t.integer  "cancelled_order_id"
    t.string   "url",                :limit => 1000,                       :null => false
    t.datetime "expires_at",                                               :null => false
    t.datetime "expired_at"
    t.string   "state",              :limit => 16,   :default => "active", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tracking_number",    :limit => 64,                         :null => false
    t.string   "tx_id",              :limit => 128,                        :null => false
    t.string   "document",                                                 :null => false
  end

  add_index "shipping_labels", ["cancelled_order_id"], :name => "shipping_labels_cancelled_order_id_fk"
  add_index "shipping_labels", ["order_id"], :name => "shipping_labels_order_id_fk"
  add_index "shipping_labels", ["state", "expires_at"], :name => "index_shipping_labels_on_state_and_expires_at"
  add_index "shipping_labels", ["state"], :name => "index_shipping_labels_on_state"

  create_table "shipping_options", :force => true do |t|
    t.integer  "listing_id",                                              :null => false
    t.string   "code",       :limit => 32,                                :null => false
    t.decimal  "rate",                     :precision => 18, :scale => 2, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shipping_options", ["listing_id"], :name => "shipping_options_listing_id_fk"

  create_table "tag_offers", :force => true do |t|
    t.integer  "tag_id",     :null => false
    t.integer  "offer_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tag_offers", ["offer_id"], :name => "tag_offers_offer_id_fk"
  add_index "tag_offers", ["tag_id"], :name => "tag_offers_tag_id_fk"

  create_table "tags", :force => true do |t|
    t.string   "name",           :limit => 128,                    :null => false
    t.string   "slug",           :limit => 128,                    :null => false
    t.integer  "primary_tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",           :limit => 1
    t.boolean  "internal",                      :default => false
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true
  add_index "tags", ["primary_tag_id", "name", "type"], :name => "index_tags_on_primary_tag_id_and_name_and_type"
  add_index "tags", ["slug"], :name => "index_tags_on_slug", :unique => true

  create_table "user_autofollows", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "position",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_autofollows", ["position"], :name => "index_user_autofollows_on_position"
  add_index "user_autofollows", ["user_id"], :name => "index_user_autofollows_on_user_id", :unique => true

  create_table "user_interests", :force => true do |t|
    t.integer  "user_id"
    t.integer  "interest_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_interests", ["interest_id"], :name => "user_interests_interest_id_fk"
  add_index "user_interests", ["user_id", "interest_id"], :name => "index_user_interests_on_user_id_and_interest_id"

  create_table "user_suggestions", :force => true do |t|
    t.integer  "user_id",                     :null => false
    t.integer  "position",                    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "interest_id", :default => -1, :null => false
  end

  add_index "user_suggestions", ["interest_id", "user_id"], :name => "index_user_suggestions_on_interest_id_and_user_id", :unique => true
  add_index "user_suggestions", ["user_id"], :name => "user_suggestions_user_id_fk"

  create_table "users", :force => true do |t|
    t.string   "uuid",                 :limit => 64
    t.integer  "person_id",                                                 :null => false
    t.string   "email"
    t.string   "encrypted_password",   :limit => 128
    t.string   "slug"
    t.string   "name",                 :limit => 128
    t.string   "firstname",            :limit => 64
    t.string   "lastname",             :limit => 64
    t.datetime "registered_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                                :default => false,   :null => false
    t.string   "reset_password_token"
    t.string   "payment_email"
    t.string   "profile_photo"
    t.datetime "remember_created_at"
    t.string   "state",                :limit => 32,   :default => "guest", :null => false
    t.datetime "connected_at"
    t.string   "visitor_id",           :limit => 64
    t.string   "location"
    t.string   "web_site"
    t.string   "bio",                  :limit => 300
    t.boolean  "web_site_enabled",                     :default => false,   :null => false
    t.integer  "listing_access",       :limit => 2
    t.boolean  "superuser",                            :default => false,   :null => false
    t.boolean  "needs_onboarding",                     :default => false,   :null => false
    t.string   "balanced_url",         :limit => 1000
    t.boolean  "inviter",                              :default => false
    t.boolean  "commenter",                            :default => false
  end

  add_index "users", ["connected_at"], :name => "index_users_on_connected_at"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["payment_email"], :name => "index_users_on_payment_email"
  add_index "users", ["person_id"], :name => "users_person_id_fk"
  add_index "users", ["registered_at"], :name => "index_users_on_registered_at"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["slug"], :name => "index_users_on_slug", :unique => true
  add_index "users", ["state"], :name => "index_users_on_state"
  add_index "users", ["uuid"], :name => "index_users_on_uuid", :unique => true

  create_table "wants", :force => true do |t|
    t.integer  "user_id",                                   :null => false
    t.integer  "item_id",                                   :null => false
    t.decimal  "max_price",  :precision => 18, :scale => 2
    t.string   "condition"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "wants", ["item_id"], :name => "wants_item_id_fk"
  add_index "wants", ["user_id", "item_id"], :name => "index_wants_on_user_id_and_item_id", :unique => true

  add_foreign_key "api_configs", "users", :name => "api_configs_user_id_fk"

  add_foreign_key "cancelled_orders", "listings", :name => "cancelled_orders_listing_id_fk"

  add_foreign_key "collection_autofollows", "collections", :name => "collection_autofollows_collection_id_fk"
  add_foreign_key "collection_autofollows", "interests", :name => "collection_autofollows_interest_id_fk"

  add_foreign_key "collection_follows", "collections", :name => "collection_follows_collection_id_fk"
  add_foreign_key "collection_follows", "users", :name => "collection_follows_user_id_fk"

  add_foreign_key "collections", "users", :name => "collections_user_id_fk"

  add_foreign_key "contacts", "email_accounts", :name => "contacts_email_account_id_fk"

  add_foreign_key "credits", "offers", :name => "credits_offer_id_fk"
  add_foreign_key "credits", "users", :name => "credits_user_id_fk"

  add_foreign_key "debits", "credits", :name => "debits_credit_id_fk"
  add_foreign_key "debits", "orders", :name => "debits_order_id_fk"

  add_foreign_key "deposit_accounts", "users", :name => "deposit_accounts_user_id_fk"

  add_foreign_key "dimension_value_listing_attachments", "dimension_values", :name => "dimension_value_listing_attachments_dimension_value_id_fk"
  add_foreign_key "dimension_value_listing_attachments", "listings", :name => "dimension_value_listing_attachments_listing_id_fk"

  add_foreign_key "dimension_values", "dimensions", :name => "dimension_values_dimension_id_fk", :dependent => :delete

  add_foreign_key "dimensions", "categories", :name => "dimensions_category_id_fk", :dependent => :delete

  add_foreign_key "dislikes", "listings", :name => "dislikes_listing_id_fk"
  add_foreign_key "dislikes", "users", :name => "dislikes_user_id_fk"

  add_foreign_key "email_accounts", "users", :name => "email_accounts_user_id_fk"

  add_foreign_key "follow_tombstones", "users", :name => "follow_tombstones_follower_id_fk", :column => "follower_id"
  add_foreign_key "follow_tombstones", "users", :name => "follow_tombstones_user_id_fk"

  add_foreign_key "follows", "users", :name => "follows_follower_id_fk", :column => "follower_id"
  add_foreign_key "follows", "users", :name => "follows_user_id_fk"

  add_foreign_key "haves", "items", :name => "haves_item_id_fk"
  add_foreign_key "haves", "users", :name => "haves_user_id_fk"

  add_foreign_key "invite_acceptances", "users", :name => "invite_acceptances_user_id_fk"

  add_foreign_key "listing_collection_attachments", "collections", :name => "listing_collection_attachments_collection_id_fk"
  add_foreign_key "listing_collection_attachments", "listings", :name => "listing_collection_attachments_listing_id_fk"

  add_foreign_key "listing_features", "listings", :name => "listing_features_listing_id_fk"

  add_foreign_key "listing_flags", "listings", :name => "listing_flags_listing_id_fk"
  add_foreign_key "listing_flags", "users", :name => "listing_flags_user_id_fk"

  add_foreign_key "listing_offers", "listings", :name => "listing_offers_listing_id_fk"
  add_foreign_key "listing_offers", "users", :name => "listing_offers_user_id_fk"

  add_foreign_key "listing_photos", "listings", :name => "listing_photos_listing_id_fk"

  add_foreign_key "listing_tag_attachments", "listings", :name => "listing_tag_attachments_listing_id_fk"
  add_foreign_key "listing_tag_attachments", "tags", :name => "listing_tag_attachments_tag_id_fk"

  add_foreign_key "listings", "categories", :name => "listings_category_id_fk"
  add_foreign_key "listings", "listing_sources", :name => "listings_listing_source_id_fk"
  add_foreign_key "listings", "tags", :name => "listings_brand_id_fk", :column => "brand_id"
  add_foreign_key "listings", "tags", :name => "listings_size_id_fk", :column => "size_id"
  add_foreign_key "listings", "users", :name => "listings_buyer_id_fk", :column => "buyer_id"
  add_foreign_key "listings", "users", :name => "listings_seller_id_fk", :column => "seller_id"

  add_foreign_key "order_ratings", "cancelled_orders", :name => "order_ratings_cancelled_order_id_fk"
  add_foreign_key "order_ratings", "orders", :name => "order_ratings_order_id_fk"
  add_foreign_key "order_ratings", "users", :name => "order_ratings_user_id_fk"

  add_foreign_key "orders", "listings", :name => "orders_listing_id_fk"
  add_foreign_key "orders", "users", :name => "orders_buyer_id_fk", :column => "buyer_id"

  add_foreign_key "paypal_payments", "deposit_accounts", :name => "paypal_payments_deposit_account_id_fk"
  add_foreign_key "paypal_payments", "orders", :name => "paypal_payments_order_id_fk"

  add_foreign_key "postal_addresses", "cancelled_orders", :name => "postal_addresses_cancelled_order_id_fk"
  add_foreign_key "postal_addresses", "listings", :name => "postal_addresses_listing_id_fk"
  add_foreign_key "postal_addresses", "orders", :name => "postal_addresses_order_id_fk"
  add_foreign_key "postal_addresses", "users", :name => "postal_addresses_user_id_fk"

  add_foreign_key "price_alerts", "listings", :name => "price_alerts_listing_id_fk"
  add_foreign_key "price_alerts", "users", :name => "price_alerts_user_id_fk"

  add_foreign_key "secret_seller_items", "users", :name => "secret_seller_items_seller_id_fk", :column => "seller_id"

  add_foreign_key "seller_offers", "offers", :name => "seller_offers_offer_id_fk"
  add_foreign_key "seller_offers", "users", :name => "seller_offers_seller_id_fk", :column => "seller_id"

  add_foreign_key "seller_payments", "deposit_accounts", :name => "seller_payments_deposit_account_id_fk"
  add_foreign_key "seller_payments", "orders", :name => "seller_payments_order_id_fk"

  add_foreign_key "shipments", "orders", :name => "shipments_order_id_fk"

  add_foreign_key "shipping_labels", "cancelled_orders", :name => "shipping_labels_cancelled_order_id_fk"
  add_foreign_key "shipping_labels", "orders", :name => "shipping_labels_order_id_fk"

  add_foreign_key "shipping_options", "listings", :name => "shipping_options_listing_id_fk"

  add_foreign_key "tag_offers", "offers", :name => "tag_offers_offer_id_fk"
  add_foreign_key "tag_offers", "tags", :name => "tag_offers_tag_id_fk"

  add_foreign_key "tags", "tags", :name => "tags_primary_tag_id_fk", :column => "primary_tag_id"

  add_foreign_key "user_autofollows", "users", :name => "user_autofollows_user_id_fk"

  add_foreign_key "user_interests", "interests", :name => "user_interests_interest_id_fk"
  add_foreign_key "user_interests", "users", :name => "user_interests_user_id_fk"

  add_foreign_key "user_suggestions", "interests", :name => "user_suggestions_interest_id_fk"
  add_foreign_key "user_suggestions", "users", :name => "user_suggestions_user_id_fk"

  add_foreign_key "users", "people", :name => "users_person_id_fk"

  add_foreign_key "wants", "items", :name => "wants_item_id_fk"
  add_foreign_key "wants", "users", :name => "wants_user_id_fk"

end
