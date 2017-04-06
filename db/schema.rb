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

ActiveRecord::Schema.define(version: 20170406072707) do

  create_table "jids", id: false, force: :cascade do |t|
    t.string "jid",  limit: 255,      null: false
    t.text   "load", limit: 16777215, null: false
  end

  add_index "jids", ["jid"], name: "jid", unique: true, using: :btree

  create_table "minions", force: :cascade do |t|
    t.string   "hostname",   limit: 255
    t.integer  "role",       limit: 4
    t.integer  "highstate",  limit: 4,   default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "minions", ["hostname"], name: "index_minions_on_hostname", unique: true, using: :btree

  create_table "pillars", force: :cascade do |t|
    t.string   "minion_id",  limit: 255
    t.string   "pillar",     limit: 255
    t.string   "value",      limit: 255
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

  add_index "salt_events", ["tag"], name: "tag", using: :btree

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
    t.string   "email",                  limit: 255,   default: "", null: false
    t.string   "encrypted_password",     limit: 255,   default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,     default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.text     "ec2_configuration",      limit: 65535
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
