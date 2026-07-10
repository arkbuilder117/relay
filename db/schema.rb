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

ActiveRecord::Schema[8.0].define(version: 2026_06_19_191258) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "apple_music_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "music_user_token", null: false
    t.string "storefront", default: "us", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_apple_music_accounts_on_user_id", unique: true
  end

  create_table "migration_playlist_results", force: :cascade do |t|
    t.bigint "migration_id", null: false
    t.string "source_id", null: false
    t.string "dest_id"
    t.string "name", null: false
    t.string "status", default: "pending", null: false
    t.integer "total_tracks", default: 0
    t.integer "matched_count", default: 0
    t.integer "unmatched_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "failure_reason"
    t.index ["migration_id"], name: "index_migration_playlist_results_on_migration_id"
  end

  create_table "migration_track_results", force: :cascade do |t|
    t.bigint "migration_playlist_result_id", null: false
    t.string "isrc"
    t.string "title", null: false
    t.string "artist", null: false
    t.string "source_id", null: false
    t.string "dest_id"
    t.string "match_status", null: false
    t.string "match_strategy"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["isrc"], name: "index_migration_track_results_on_isrc"
    t.index ["match_status"], name: "index_migration_track_results_on_match_status"
    t.index ["migration_playlist_result_id"], name: "index_migration_track_results_on_migration_playlist_result_id"
  end

  create_table "migrations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "direction", null: false
    t.string "status", default: "pending", null: false
    t.integer "total_playlists", default: 0
    t.integer "total_tracks", default: 0
    t.integer "matched_tracks", default: 0
    t.integer "unmatched_tracks", default: 0
    t.text "failure_reason"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "include_liked_songs", default: false, null: false
    t.index ["status"], name: "index_migrations_on_status"
    t.index ["user_id"], name: "index_migrations_on_user_id"
  end

  create_table "spotify_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "spotify_id", null: false
    t.string "display_name"
    t.string "access_token", null: false
    t.string "refresh_token", null: false
    t.datetime "token_expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spotify_id"], name: "index_spotify_accounts_on_spotify_id", unique: true
    t.index ["user_id"], name: "index_spotify_accounts_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "apple_music_accounts", "users"
  add_foreign_key "migration_playlist_results", "migrations"
  add_foreign_key "migration_track_results", "migration_playlist_results"
  add_foreign_key "migrations", "users"
  add_foreign_key "spotify_accounts", "users"
end
