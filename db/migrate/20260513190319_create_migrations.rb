class CreateMigrations < ActiveRecord::Migration[8.0]
  def change
    create_table :migrations do |t|
      t.references :user,      null: false, foreign_key: true
      t.string     :direction, null: false
      t.string     :status,    null: false, default: "pending"
      t.integer    :total_playlists,   default: 0
      t.integer    :total_tracks,      default: 0
      t.integer    :matched_tracks,    default: 0
      t.integer    :unmatched_tracks,  default: 0
      t.text       :failure_reason
      t.datetime   :started_at
      t.datetime   :completed_at
      t.timestamps
    end
    add_index :migrations, :status
  end
end
