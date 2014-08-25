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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140825180018) do

  create_table "definitions", force: true do |t|
    t.integer  "service_id"
    t.integer  "user_id"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "destination_fields", force: true do |t|
    t.integer  "definition_id"
    t.string   "name"
    t.string   "display_name"
    t.string   "description"
    t.string   "data_type"
    t.string   "statement"
    t.string   "uri"
    t.boolean  "allows_duplicate"
    t.boolean  "allows_null"
    t.boolean  "is_read_only"
    t.boolean  "is_required"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mappings", force: true do |t|
    t.integer  "definition_id"
    t.string   "source_header"
    t.integer  "destination_field_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "services", force: true do |t|
    t.integer  "user_id"
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "oauth_token"
    t.string   "token_type"
    t.integer  "expires_in"
    t.text     "refresh_token"
    t.string   "name"
    t.string   "auth_type"
    t.string   "auth_path"
    t.string   "api_domain"
    t.string   "auth_domain"
    t.string   "app_api_key"
    t.string   "app_api_secret"
    t.string   "api_path"
    t.string   "token_path"
    t.string   "auth_user"
  end

  create_table "sync_operations", force: true do |t|
    t.integer  "definition_id"
    t.string   "name"
    t.string   "assigned_service_id"
    t.text     "source_data"
    t.text     "response"
    t.string   "rejects_uri"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
