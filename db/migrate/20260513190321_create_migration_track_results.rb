class CreateMigrationTrackResults < ActiveRecord::Migration[8.0]
  def change
    create_table :migration_track_results do |t|
      t.references :migration_playlist_result, null: false, foreign_key: true
      t.string  :isrc
      t.string  :title,          null: false
      t.string  :artist,         null: false
      t.string  :source_id,      null: false
      t.string  :dest_id
      t.string  :match_status,   null: false
      t.string  :match_strategy
      t.timestamps
    end
    add_index :migration_track_results, :isrc
    add_index :migration_track_results, :match_status
  end
end
