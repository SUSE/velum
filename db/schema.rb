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

ActiveRecord::Schema.define(version: 20170124170136) do

  create_table "jids", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "jid",                   null: false
    t.text   "load", limit: 16777215, null: false
    t.index ["jid"], name: "jid", unique: true, using: :btree
  end

  create_table "minions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "hostname"
    t.integer  "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hostname"], name: "index_minions_on_hostname", unique: true, using: :btree
  end

  create_table "salt_events", id: :bigint, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "tag",                                                                null: false
    t.text     "data",         limit: 16777215,                                      null: false
    t.datetime "alter_time",                    default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string   "master_id",                                                          null: false
    t.datetime "taken_at"
    t.datetime "processed_at"
    t.string   "worker_id"
    t.index ["tag"], name: "tag", using: :btree
  end

  create_table "salt_returns", id: false, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "fun",        limit: 50,                                            null: false
    t.string   "jid",                                                              null: false
    t.text     "return",     limit: 16777215,                                      null: false
    t.string   "id",                                                               null: false
    t.string   "success",    limit: 10,                                            null: false
    t.text     "full_ret",   limit: 16777215,                                      null: false
    t.datetime "alter_time",                  default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["fun"], name: "fun", using: :btree
    t.index ["id"], name: "id", using: :btree
    t.index ["jid"], name: "jid", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
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
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

end
