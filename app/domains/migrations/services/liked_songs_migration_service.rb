module Migrations
  module Services
    class LikedSongsMigrationService
      def initialize(migration)
        @migration = migration
      end

      def migrate(playlist_result)
        tracks = fetch_source_tracks

        playlist_result.update!(total_tracks: tracks.size)

        isrc_map  = build_isrc_map(tracks)
        dest_ids  = []
        matched   = 0
        unmatched = 0

        tracks.each do |track|
          dest_id, strategy = resolve_track(track, isrc_map)

          if dest_id
            matched += 1
            dest_ids << dest_id
          else
            unmatched += 1
            strategy = "none"
          end

          MigrationTrackResult.create!(
            migration_playlist_result_id: playlist_result.id,
            isrc:           track.isrc,
            title:          track.title,
            artist:         track.artist,
            source_id:      track.id,
            dest_id:        dest_id,
            match_status:   dest_id ? "matched" : "unmatched",
            match_strategy: strategy
          )
        end

        save_dest_tracks(dest_ids) if dest_ids.any?

        playlist_result.update!(
          status:          "completed",
          matched_count:   matched,
          unmatched_count: unmatched
        )

        playlist_result.reload
      end

      private

      # TODO: remove testing limit before launch
      TESTING_LIMIT = 10

      def fetch_source_tracks
        if @migration.direction == "spotify_to_apple"
          account = SpotifyAccount.find_by(user_id: @migration.user_id)
          token   = Spotify::Services::AuthService.fresh_token(account)
          Spotify::Services::LikedSongsFetcher.new(token).fetch_all.first(TESTING_LIMIT) # TODO: remove limit
        else
          account = AppleMusicAccount.find_by(user_id: @migration.user_id)
          AppleMusic::Services::FavoritedSongsFetcher.new(account).fetch_all.first(TESTING_LIMIT) # TODO: remove limit
        end
      end

      def build_isrc_map(tracks)
        isrcs = tracks.map(&:isrc).compact.select { |i| Catalog::Services::ISRCMatcher.valid?(i) }
        return {} if isrcs.empty?

        if @migration.direction == "spotify_to_apple"
          account = AppleMusicAccount.find_by(user_id: @migration.user_id)
          AppleMusic::Services::TrackSearcher.new(account).search_by_isrc_batch(isrcs)
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

      def resolve_track(track, isrc_map)
        if Catalog::Services::ISRCMatcher.valid?(track.isrc) && isrc_map[track.isrc]
          candidates = isrc_map[track.isrc]
          best       = best_album_match(candidates, track.album)
          return [ best.id, "isrc" ]
        end

        [ nil, nil ]
      end

      def best_album_match(candidates, source_album)
        return candidates.first if candidates.size == 1 || source_album.nil?

        candidates.find { |c| c.album.to_s.downcase == source_album.to_s.downcase } ||
          candidates.first
      end

      def save_dest_tracks(dest_ids)
        if @migration.direction == "spotify_to_apple"
          account = AppleMusicAccount.find_by(user_id: @migration.user_id)
          AppleMusic::Services::FavoritedSongsSaver.new(account).save(dest_ids)
        else
          account = SpotifyAccount.find_by(user_id: @migration.user_id)
          token   = Spotify::Services::AuthService.fresh_token(account)
          Spotify::Services::LikedSongsSaver.new(token).save(dest_ids)
        end
      end
    end
  end
end
