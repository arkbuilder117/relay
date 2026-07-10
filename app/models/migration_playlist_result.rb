class MigrationPlaylistResult < ApplicationRecord
  belongs_to :migration
  has_many :track_results, class_name: "MigrationTrackResult",
                           foreign_key: :migration_playlist_result_id,
                           dependent: :destroy

  def match_percentage
    return 0 if total_tracks.zero?
    ((matched_count.to_f / total_tracks) * 100).round
  end
end
