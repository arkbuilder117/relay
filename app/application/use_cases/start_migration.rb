module UseCases
  class StartMigration
    VALID_DIRECTIONS = %w[spotify_to_apple apple_to_spotify].freeze

    def call(user:, direction:, playlist_ids: [], include_liked_songs: false)
      raise "Invalid direction"                 unless VALID_DIRECTIONS.include?(direction)
      raise "Spotify account not connected"     unless SpotifyAccount.exists?(user_id: user.id)
      raise "Apple Music account not connected" unless AppleMusicAccount.exists?(user_id: user.id)

      existing = Migration.find_by(user_id: user.id, status: %w[pending in_progress])
      return existing if existing

      raise "Nothing selected" if playlist_ids.empty? && !include_liked_songs

      all_playlists = playlist_ids.any? ? UseCases::FetchUserPlaylists.new.call(user: user, direction: direction) : []
      selected      = all_playlists.select { |p| playlist_ids.include?(p.id) }

      raise "No valid playlists selected" if playlist_ids.any? && selected.empty?

      migration = Migration.create!(
        user_id:             user.id,
        direction:           direction,
        total_playlists:     selected.size + (include_liked_songs ? 1 : 0),
        include_liked_songs: include_liked_songs
      )

      if include_liked_songs
        liked_name = direction == "spotify_to_apple" ? "Liked Songs" : "Favorite Songs"
        MigrationPlaylistResult.create!(
          migration_id: migration.id,
          source_id:    Migrations::LIKED_SONGS_SOURCE_ID,
          name:         liked_name,
          status:       "pending"
        )
      end

      selected.each do |playlist|
        MigrationPlaylistResult.create!(
          migration_id: migration.id,
          source_id:    playlist.id,
          name:         playlist.name,
          status:       "pending"
        )
      end

      MigrationJob.perform_later(migration.id)
      migration
    end
  end
end
