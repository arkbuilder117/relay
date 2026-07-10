module Migrations
  module Services
    class PlaylistMigrationService
      def initialize(migration)
        @migration = migration
      end

      def migrate_playlist(source_playlist, playlist_result)
        direction = @migration.direction
        tracks    = fetch_source_tracks(direction, source_playlist.id)

        playlist_result.update!(total_tracks: tracks.size)

        isrc_map  = build_isrc_map(direction, tracks)
        dest_ids  = []
        matched   = 0
        unmatched = 0

        tracks.each do |track|
          dest_id, strategy = resolve_track(direction, track, isrc_map)

          if dest_id
            matched += 1
            status   = strategy == "fuzzy" ? "fuzzy_matched" : "matched"
            dest_ids << dest_id
          else
            unmatched += 1
            status    = "unmatched"
          end

          MigrationTrackResult.create!(
            migration_playlist_result_id: playlist_result.id,
            isrc:           track.isrc,
            title:          track.title,
            artist:         track.artist,
            source_id:      track.id,
            dest_id:        dest_id,
            match_status:   status,
            match_strategy: dest_id ? strategy : "none"
          )
        end

        dest_playlist_id = create_dest_playlist(direction, source_playlist.name, dest_ids)

        playlist_result.update!(
          dest_id:         dest_playlist_id,
          status:          "completed",
          matched_count:   matched,
          unmatched_count: unmatched
        )

        playlist_result.reload
      end

      private

      def fetch_source_tracks(direction, playlist_id)
        if direction == "spotify_to_apple"
          account = SpotifyAccount.find_by(user_id: @migration.user_id)
          token   = Spotify::Services::AuthService.fresh_token(account)
          Spotify::Services::TrackFetcher.new(token).fetch_all(playlist_id)
        else
          account = AppleMusicAccount.find_by(user_id: @migration.user_id)
          AppleMusic::Services::TrackFetcher.new(account).fetch_all(playlist_id)
        end
      end

      def build_isrc_map(direction, tracks)
        isrcs = tracks.map(&:isrc).compact.select { |i| Catalog::Services::ISRCMatcher.valid?(i) }
        return {} if isrcs.empty?

        if direction == "spotify_to_apple"
          apple_account = AppleMusicAccount.find_by(user_id: @migration.user_id)
          AppleMusic::Services::TrackSearcher.new(apple_account).search_by_isrc_batch(isrcs)
        else
          account  = SpotifyAccount.find_by(user_id: @migration.user_id)
          token    = Spotify::Services::AuthService.fresh_token(account)
          searcher = Spotify::Services::TrackSearcher.new(token)
          isrcs.each_with_object({}) do |isrc, map|
            result    = searcher.search_by_isrc(isrc)
            map[isrc] = [ result ] if result
          end
        end
      end

      def resolve_track(direction, track, isrc_map)
        if Catalog::Services::ISRCMatcher.valid?(track.isrc) && isrc_map[track.isrc]
          candidates = isrc_map[track.isrc]
          best       = best_album_match(candidates, track.album)
          return [ best.id, "isrc" ]
        end

        [ nil, nil ]
      end

      def best_album_match(candidates, source_album)
        return candidates.first if candidates.size == 1 || source_album.nil?

        source_norm = normalize_album(source_album)

        candidates.find { |c| normalize_album(c.album) == source_norm } ||
          candidates.find { |c| album_contains?(normalize_album(c.album), source_norm) } ||
          candidates.first
      end

      def normalize_album(name)
        name.to_s.downcase.gsub(/\s*[\(\[].*?[\)\]]\s*/, "").strip
      end

      def album_contains?(a, b)
        a.include?(b) || b.include?(a)
      end

      def create_dest_playlist(direction, name, track_ids)
        return nil if track_ids.empty?
        if direction == "spotify_to_apple"
          apple_account = AppleMusicAccount.find_by(user_id: @migration.user_id)
          AppleMusic::Services::PlaylistCreator.new(apple_account).create(name: name, track_ids: track_ids)
        else
          spotify_account = SpotifyAccount.find_by(user_id: @migration.user_id)
          token           = Spotify::Services::AuthService.fresh_token(spotify_account)
          Spotify::Services::PlaylistCreator.new(token, spotify_account.spotify_id).create(name: name, track_ids: track_ids)
        end
      end
    end
  end
end
