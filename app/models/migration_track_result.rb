class MigrationTrackResult < ApplicationRecord
  belongs_to :migration_playlist_result

  def matched?       = match_status == "matched"
  def fuzzy_matched? = match_status == "fuzzy_matched"
  def unmatched?     = match_status == "unmatched"
end
