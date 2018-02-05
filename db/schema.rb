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

ActiveRecord::Schema.define(version: 20180206150021) do

  create_table "certificate_services", force: :cascade do |t|
    t.integer  "certificate_id", limit: 4
    t.integer  "service_id",     limit: 4
    t.string   "service_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "certificate_services", ["certificate_id", "service_id", "service_type"], name: "index_certificate_services_on_certificate_id_and_service", unique: true, using: :btree

  create_table "certificates", force: :cascade do |t|
    t.text     "certificate", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "registries", force: :cascade do |t|
    t.string   "url",        limit: 255
    t.string   "mirror",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "jids", id: false, force: :cascade do |t|
    t.string "jid",  limit: 255,      null: false
    t.text   "load", limit: 16777215, null: false
  end

  add_index "jids", ["jid"], name: "jid", unique: true, using: :btree

  create_table "minions", force: :cascade do |t|
    t.string   "minion_id",  limit: 255
    t.string   "fqdn",       limit: 255
    t.integer  "role",       limit: 4
    t.integer  "highstate",  limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "minions", ["fqdn"], name: "index_minions_on_fqdn", using: :btree
  add_index "minions", ["minion_id"], name: "index_minions_on_minion_id", unique: true, using: :btree

  create_table "orchestrations", force: :cascade do |t|
    t.string   "jid",         limit: 255
    t.integer  "kind",        limit: 4
    t.integer  "status",      limit: 4,   default: 0
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "orchestrations", ["jid"], name: "index_orchestrations_on_jid", using: :btree
  add_index "orchestrations", ["kind", "status"], name: "index_orchestrations_on_kind_and_status", using: :btree

  create_table "pillars", force: :cascade do |t|
    t.string   "minion_id",  limit: 255
    t.string   "pillar",     limit: 255
    t.text     "value",      limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pillars", ["minion_id"], name: "index_pillars_on_minion_id", using: :btree
  add_index "pillars", ["pillar"], name: "index_pillars_on_pillar", using: :btree

  create_table "salt_events", force: :cascade do |t|
    t.string   "tag",          limit: 255,      null: false
    t.text     "data",         limit: 16777215, null: false
    t.datetime "alter_time",                    null: false
    t.string   "master_id",    limit: 255,      null: false
    t.datetime "taken_at"
    t.datetime "processed_at"
    t.string   "worker_id",    limit: 255
  end

  add_index "salt_events", ["processed_at"], name: "index_salt_events_on_processed_at", using: :btree
  add_index "salt_events", ["tag"], name: "tag", using: :btree
  add_index "salt_events", ["worker_id", "taken_at"], name: "index_salt_events_on_worker_id_and_taken_at", using: :btree

  create_table "salt_returns", id: false, force: :cascade do |t|
    t.string   "fun",        limit: 50,       null: false
    t.string   "jid",        limit: 255,      null: false
    t.text     "return",     limit: 16777215, null: false
    t.string   "id",         limit: 255,      null: false
    t.string   "success",    limit: 10,       null: false
    t.text     "full_ret",   limit: 16777215, null: false
    t.datetime "alter_time",                  null: false
  end

  add_index "salt_returns", ["fun"], name: "fun", using: :btree
  add_index "salt_returns", ["id"], name: "id", using: :btree
  add_index "salt_returns", ["jid"], name: "jid", using: :btree

  create_table "users", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.string   "remember_token",         limit: 150
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
