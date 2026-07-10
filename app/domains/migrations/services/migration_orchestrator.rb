module Migrations
  module Services
    class MigrationOrchestrator
      def initialize(migration, user)
        @migration = migration
        @user      = user
        @callbacks = {}
      end

      def on(event, &block)
        @callbacks[event] = block
        self
      end

      def run
        @migration.update!(status: "in_progress", started_at: Time.current)

        pending_results = @migration.playlist_results.where.not(status: "completed").to_a

        completed       = @migration.playlist_results.where(status: "completed")
        total_matched   = completed.sum(:matched_count)
        total_unmatched = completed.sum(:unmatched_count)
        total_tracks    = completed.sum(:total_tracks)

        liked_result     = pending_results.find { |r| r.source_id == Migrations::LIKED_SONGS_SOURCE_ID }
        playlist_results = pending_results.reject { |r| r.source_id == Migrations::LIKED_SONGS_SOURCE_ID }

        if liked_result
          updated = LikedSongsMigrationService.new(@migration).migrate(liked_result)
          total_matched   += updated.matched_count
          total_unmatched += updated.unmatched_count
          total_tracks    += updated.total_tracks
          @migration.update!(total_tracks: total_tracks, matched_tracks: total_matched, unmatched_tracks: total_unmatched)
          @callbacks[:playlist_completed]&.call(updated)
        end

        source_playlists = fetch_source_playlists(@migration.direction)
        source_map       = source_playlists.index_by(&:id)

        playlist_results.each do |playlist_result|
          playlist = source_map[playlist_result.source_id]

          unless playlist
            playlist_result.update!(status: "failed", failure_reason: "Playlist no longer exists on source")
            @callbacks[:playlist_completed]&.call(playlist_result.reload)
            next
          end

          updated_result = begin
            service = PlaylistMigrationService.new(@migration)
            service.migrate_playlist(playlist, playlist_result)
          rescue Http::SpotifyForbiddenError => e
            Rails.logger.error("[MigrationOrchestrator] #{playlist.id} (#{playlist.name}): #{e.message}")
            playlist_result.update!(status: "failed", failure_reason: e.message)
            playlist_result.reload
          end

          total_matched   += updated_result.matched_count
          total_unmatched += updated_result.unmatched_count
          total_tracks    += updated_result.total_tracks

          @migration.update!(
            total_tracks:     total_tracks,
            matched_tracks:   total_matched,
            unmatched_tracks: total_unmatched
          )

          @callbacks[:playlist_completed]&.call(updated_result)
        end

        @migration.update!(status: "completed", completed_at: Time.current)
      rescue StandardError => e
        @migration&.update!(status: "failed", failure_reason: e.message)
        raise
      end

      private

      def fetch_source_playlists(direction)
        if direction == "spotify_to_apple"
          account = SpotifyAccount.find_by(user_id: @user.id)
          token   = Spotify::Services::AuthService.fresh_token(account)
          Spotify::Services::PlaylistFetcher.new(token, account.spotify_id).fetch_all
        else
          account = AppleMusicAccount.find_by(user_id: @user.id)
          AppleMusic::Services::PlaylistFetcher.new(account).fetch_all
        end
      end
    end
  end
end
