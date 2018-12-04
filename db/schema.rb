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

ActiveRecord::Schema.define(version: 20182106194301) do

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

  create_table "dex_connectors_ldap", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",               limit: 255
    t.string   "host",               limit: 255
    t.integer  "port",               limit: 2
    t.boolean  "start_tls",                      null: false
    t.boolean  "bind_anon",                      null: false
    t.string   "bind_dn",            limit: 255
    t.string   "bind_pw",            limit: 255
    t.string   "username_prompt",    limit: 255
    t.string   "user_base_dn",       limit: 255
    t.string   "user_filter",        limit: 255
    t.string   "user_attr_username", limit: 255
    t.string   "user_attr_id",       limit: 255
    t.string   "user_attr_email",    limit: 255, null: false
    t.string   "user_attr_name",     limit: 255
    t.string   "group_base_dn",      limit: 255
    t.string   "group_filter",       limit: 255
    t.string   "group_attr_user",    limit: 255
    t.string   "group_attr_group",   limit: 255
    t.string   "group_attr_name",    limit: 255
  end

  add_index "dex_connectors_ldap", ["id"], name: "index_dex_connectors_ldap_on_id", unique: true, using: :btree

  create_table "jids", id: false, force: :cascade do |t|
    t.string "jid",  limit: 255,      null: false
    t.text   "load", limit: 16777215, null: false
  end

  add_index "jids", ["jid"], name: "jid", unique: true, using: :btree

  create_table "kubelet_compute_resources_reservations", force: :cascade do |t|
    t.string   "component",         limit: 255,              null: false
    t.string   "cpu",               limit: 255, default: ""
    t.string   "memory",            limit: 255, default: ""
    t.string   "ephemeral_storage", limit: 255, default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "kubelet_compute_resources_reservations", ["component"], name: "index_kubelet_compute_resources_reservations_on_component", unique: true, using: :btree

  create_table "minions", force: :cascade do |t|
    t.string   "minion_id",               limit: 255
    t.string   "fqdn",                    limit: 255
    t.integer  "role",                    limit: 4
    t.integer  "highstate",               limit: 4,   default: 0
    t.boolean  "tx_update_reboot_needed",             default: false
    t.boolean  "tx_update_failed",                    default: false
    t.boolean  "tx_update_migration_available",       default: false
    t.string   "tx_update_migration_notes"
    t.boolean  "tx_update_migration_mirror_synced",   default: false
    t.string   "tx_update_migration_newversion"
    t.string   "os_release"
    t.boolean  "online",                              default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "minions", ["fqdn"], name: "index_minions_on_fqdn", using: :btree
  add_index "minions", ["minion_id"], name: "index_minions_on_minion_id", unique: true, using: :btree

  create_table "orchestrations", force: :cascade do |t|
    t.string   "jid",         limit: 255
    t.integer  "kind",        limit: 4
    t.text     "params",      limit: 65535
    t.integer  "status",      limit: 4,     default: 0
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

  create_table "registries", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "url",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "registry_mirrors", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "url",         limit: 255
    t.integer  "registry_id", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "registry_mirrors", ["registry_id"], name: "index_registry_mirrors_on_registry_id", using: :btree

  create_table "salt_events", force: :cascade do |t|
    t.string   "tag",          limit: 255,      null: false
    t.text     "data",         limit: 16777215, null: false
    t.column   "alter_time",   "DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP"
    t.string   "master_id",    limit: 255,      null: false
    t.datetime "taken_at"
    t.datetime "processed_at"
    t.string   "worker_id",    limit: 255
  end

  add_index "salt_events", ["processed_at"], name: "index_salt_events_on_processed_at", using: :btree
  add_index "salt_events", ["tag"], name: "tag", using: :btree
  add_index "salt_events", ["worker_id", "taken_at"], name: "index_salt_events_on_worker_id_and_taken_at", using: :btree

  create_table "salt_jobs", force: :cascade do |t|
    t.string   "jid",          limit: 255
    t.integer  "retcode",      limit: 4
    t.text     "master_trace", limit: 65535
    t.text     "minion_trace", limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "salt_jobs", ["jid"], name: "index_salt_jobs_on_jid", using: :btree

  create_table "salt_returns", id: false, force: :cascade do |t|
    t.string   "fun",        limit: 50,       null: false
    t.string   "jid",        limit: 255,      null: false
    t.text     "return",     limit: 16777215, null: false
    t.string   "id",         limit: 255,      null: false
    t.string   "success",    limit: 10,       null: false
    t.text     "full_ret",   limit: 16777215, null: false
    t.column   "alter_time", "DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP"
  end

  add_index "salt_returns", ["fun"], name: "fun", using: :btree
  add_index "salt_returns", ["id"], name: "id", using: :btree
  add_index "salt_returns", ["jid"], name: "jid", using: :btree

  create_table "system_certificates", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

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

  create_table "dex_connectors_oidc", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "provider_url",       limit: 2048
    t.string   "client_id"
    t.string   "client_secret"
    t.string   "callback_url",       limit: 2048
    t.boolean  "basic_auth",                     default: true, null: false
  end
end
