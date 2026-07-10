module Presenters
  class MigrationPresenter
    attr_reader :migration

    def initialize(migration)
      @migration = migration
    end

    def status_label
      migration.status.humanize
    end

    def direction_label
      migration.spotify_to_apple? ? "Spotify → Apple Music" : "Apple Music → Spotify"
    end

    def summary_stats
      {
        total_playlists:  migration.total_playlists,
        total_tracks:     migration.total_tracks,
        matched_tracks:   migration.matched_tracks,
        unmatched_tracks: migration.unmatched_tracks,
        match_percentage: migration.match_percentage
      }
    end
  end
end
