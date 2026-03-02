# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_02_210800) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "data_conflicts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.string "field_name", null: false
    t.bigint "frc_team_id", null: false
    t.bigint "match_id", null: false
    t.bigint "organization_id"
    t.string "resolution_value"
    t.boolean "resolved", default: false, null: false
    t.bigint "resolved_by_id"
    t.datetime "updated_at", null: false
    t.jsonb "values", default: {}, null: false
    t.index ["event_id", "frc_team_id", "match_id", "field_name"], name: "idx_data_conflicts_unique", unique: true
    t.index ["event_id"], name: "index_data_conflicts_on_event_id"
    t.index ["frc_team_id"], name: "index_data_conflicts_on_frc_team_id"
    t.index ["match_id"], name: "index_data_conflicts_on_match_id"
    t.index ["organization_id"], name: "index_data_conflicts_on_organization_id"
    t.index ["resolved_by_id"], name: "index_data_conflicts_on_resolved_by_id"
  end

  create_table "event_teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "frc_team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "frc_team_id"], name: "index_event_teams_on_event_id_and_frc_team_id", unique: true
    t.index ["event_id"], name: "index_event_teams_on_event_id"
    t.index ["frc_team_id"], name: "index_event_teams_on_frc_team_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.date "end_date"
    t.integer "event_type"
    t.string "name"
    t.bigint "organization_id"
    t.date "start_date"
    t.string "state_prov"
    t.string "tba_key"
    t.datetime "updated_at", null: false
    t.integer "week"
    t.integer "year"
    t.index ["organization_id"], name: "index_events_on_organization_id"
    t.index ["tba_key"], name: "index_events_on_tba_key", unique: true
  end

  create_table "frc_teams", force: :cascade do |t|
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "nickname"
    t.integer "rookie_year"
    t.string "state_prov"
    t.integer "team_number"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["team_number"], name: "index_frc_teams_on_team_number", unique: true
  end

  create_table "game_configs", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "game_name", null: false
    t.bigint "organization_id"
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["active"], name: "index_game_configs_on_active"
    t.index ["organization_id"], name: "index_game_configs_on_organization_id"
    t.index ["year"], name: "index_game_configs_on_year", unique: true
  end

  create_table "match_alliances", force: :cascade do |t|
    t.string "alliance_color", null: false
    t.datetime "created_at", null: false
    t.bigint "frc_team_id", null: false
    t.bigint "match_id", null: false
    t.integer "station", null: false
    t.datetime "updated_at", null: false
    t.index ["frc_team_id"], name: "index_match_alliances_on_frc_team_id"
    t.index ["match_id", "alliance_color", "station"], name: "idx_match_alliances_unique_station", unique: true
    t.index ["match_id", "frc_team_id"], name: "index_match_alliances_on_match_id_and_frc_team_id", unique: true
    t.index ["match_id"], name: "index_match_alliances_on_match_id"
  end

  create_table "matches", force: :cascade do |t|
    t.string "comp_level"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.integer "match_number"
    t.datetime "scheduled_time"
    t.integer "set_number"
    t.string "tba_key"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_matches_on_event_id"
    t.index ["tba_key"], name: "index_matches_on_tba_key", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_memberships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.jsonb "settings", default: {}, null: false
    t.string "slug", null: false
    t.integer "team_number"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
    t.index ["team_number"], name: "index_organizations_on_team_number"
  end

  create_table "pick_lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "entries"
    t.bigint "event_id", null: false
    t.string "name"
    t.bigint "organization_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id"], name: "index_pick_lists_on_event_id"
    t.index ["organization_id"], name: "index_pick_lists_on_organization_id"
    t.index ["user_id"], name: "index_pick_lists_on_user_id"
  end

  create_table "pit_scouting_entries", force: :cascade do |t|
    t.string "client_uuid"
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.bigint "event_id", null: false
    t.bigint "frc_team_id", null: false
    t.text "notes"
    t.bigint "organization_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["client_uuid"], name: "index_pit_scouting_entries_on_client_uuid", unique: true
    t.index ["data"], name: "index_pit_scouting_entries_on_data", using: :gin
    t.index ["event_id", "frc_team_id", "user_id"], name: "idx_pit_scouting_entries_unique", unique: true
    t.index ["event_id"], name: "index_pit_scouting_entries_on_event_id"
    t.index ["frc_team_id"], name: "index_pit_scouting_entries_on_frc_team_id"
    t.index ["organization_id"], name: "index_pit_scouting_entries_on_organization_id"
    t.index ["user_id"], name: "index_pit_scouting_entries_on_user_id"
  end

  create_table "predictions", force: :cascade do |t|
    t.integer "actual_blue_score"
    t.integer "actual_red_score"
    t.float "blue_score"
    t.float "blue_win_probability"
    t.datetime "created_at", null: false
    t.jsonb "details", default: {}, null: false
    t.bigint "event_id", null: false
    t.bigint "match_id", null: false
    t.bigint "organization_id"
    t.float "red_score"
    t.float "red_win_probability"
    t.string "source"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_predictions_on_event_id"
    t.index ["match_id", "organization_id", "source"], name: "idx_predictions_unique", unique: true
    t.index ["match_id"], name: "index_predictions_on_match_id"
    t.index ["organization_id"], name: "index_predictions_on_organization_id"
  end

  create_table "reports", force: :cascade do |t|
    t.jsonb "cached_data", default: {}
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "last_generated_at"
    t.string "name", null: false
    t.bigint "organization_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id"], name: "index_reports_on_event_id"
    t.index ["organization_id"], name: "index_reports_on_organization_id"
    t.index ["user_id"], name: "index_reports_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "scouting_entries", force: :cascade do |t|
    t.string "client_uuid"
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.bigint "event_id", null: false
    t.bigint "frc_team_id", null: false
    t.bigint "match_id"
    t.text "notes"
    t.bigint "organization_id"
    t.string "photo_url"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["client_uuid"], name: "index_scouting_entries_on_client_uuid", unique: true
    t.index ["data"], name: "index_scouting_entries_on_data", using: :gin
    t.index ["event_id", "frc_team_id", "match_id", "user_id"], name: "idx_scouting_entries_unique", unique: true
    t.index ["event_id"], name: "index_scouting_entries_on_event_id"
    t.index ["frc_team_id"], name: "index_scouting_entries_on_frc_team_id"
    t.index ["match_id"], name: "index_scouting_entries_on_match_id"
    t.index ["organization_id"], name: "index_scouting_entries_on_organization_id"
    t.index ["user_id"], name: "index_scouting_entries_on_user_id"
  end

  create_table "simulation_results", force: :cascade do |t|
    t.jsonb "blue_team_ids", default: [], null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.integer "iterations", default: 1000
    t.string "name"
    t.bigint "organization_id"
    t.jsonb "red_team_ids", default: [], null: false
    t.jsonb "results", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id"], name: "index_simulation_results_on_event_id"
    t.index ["organization_id"], name: "index_simulation_results_on_organization_id"
    t.index ["user_id"], name: "index_simulation_results_on_user_id"
  end

  create_table "statbotics_caches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.float "epa_mean"
    t.float "epa_sd"
    t.bigint "event_id", null: false
    t.bigint "frc_team_id", null: false
    t.datetime "last_synced_at", null: false
    t.integer "losses", default: 0
    t.integer "qual_losses", default: 0
    t.integer "qual_num_teams"
    t.integer "qual_rank"
    t.integer "qual_wins", default: 0
    t.integer "ties", default: 0
    t.datetime "updated_at", null: false
    t.float "winrate"
    t.integer "wins", default: 0
    t.index ["epa_mean"], name: "index_statbotics_caches_on_epa_mean"
    t.index ["event_id", "frc_team_id"], name: "index_statbotics_caches_on_event_id_and_frc_team_id", unique: true
    t.index ["event_id"], name: "index_statbotics_caches_on_event_id"
    t.index ["frc_team_id"], name: "index_statbotics_caches_on_frc_team_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "api_token"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "team_number"
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "user_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "data_conflicts", "events"
  add_foreign_key "data_conflicts", "frc_teams"
  add_foreign_key "data_conflicts", "matches"
  add_foreign_key "data_conflicts", "organizations"
  add_foreign_key "data_conflicts", "users", column: "resolved_by_id"
  add_foreign_key "event_teams", "events"
  add_foreign_key "event_teams", "frc_teams"
  add_foreign_key "events", "organizations"
  add_foreign_key "game_configs", "organizations"
  add_foreign_key "match_alliances", "frc_teams"
  add_foreign_key "match_alliances", "matches"
  add_foreign_key "matches", "events"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "pick_lists", "events"
  add_foreign_key "pick_lists", "organizations"
  add_foreign_key "pick_lists", "users"
  add_foreign_key "pit_scouting_entries", "events"
  add_foreign_key "pit_scouting_entries", "frc_teams"
  add_foreign_key "pit_scouting_entries", "organizations"
  add_foreign_key "pit_scouting_entries", "users"
  add_foreign_key "predictions", "events"
  add_foreign_key "predictions", "matches"
  add_foreign_key "predictions", "organizations"
  add_foreign_key "reports", "events"
  add_foreign_key "reports", "organizations"
  add_foreign_key "reports", "users"
  add_foreign_key "scouting_entries", "events"
  add_foreign_key "scouting_entries", "frc_teams"
  add_foreign_key "scouting_entries", "matches"
  add_foreign_key "scouting_entries", "organizations"
  add_foreign_key "scouting_entries", "users"
  add_foreign_key "simulation_results", "events"
  add_foreign_key "simulation_results", "organizations"
  add_foreign_key "simulation_results", "users"
  add_foreign_key "statbotics_caches", "events"
  add_foreign_key "statbotics_caches", "frc_teams"
end
