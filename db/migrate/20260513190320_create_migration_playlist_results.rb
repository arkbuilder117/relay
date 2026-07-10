class CreateMigrationPlaylistResults < ActiveRecord::Migration[8.0]
  def change
    create_table :migration_playlist_results do |t|
      t.references :migration,   null: false, foreign_key: true
      t.string     :source_id,   null: false
      t.string     :dest_id
      t.string     :name,        null: false
      t.string     :status,      null: false, default: "pending"
      t.integer    :total_tracks,    default: 0
      t.integer    :matched_count,   default: 0
      t.integer    :unmatched_count, default: 0
      t.timestamps
    end
  end
end
