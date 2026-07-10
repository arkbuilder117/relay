module UseCases
  class SearchTracks
    def call(query)
      return [] if query.blank?

      spotify_tracks = Spotify::Services::CatalogSearcher.new.search(query)
      return [] if spotify_tracks.empty?

      isrc_album_map = spotify_tracks.each_with_object({}) { |t, h| h[t[:isrc]] = t[:album] if t[:isrc] }
      apple_by_isrc  = isrc_album_map.any? ? apple_isrc_lookup(isrc_album_map) : {}

      spotify_tracks.map do |track|
        apple = apple_by_isrc[track[:isrc]]

        Catalog::ValueObjects::TrackResult.new(
          title:           track[:title],
          artist:          track[:artist],
          album:           track[:album],
          artwork_url:     track[:artwork_url] || apple&.dig(:artwork_url),
          duration_ms:     track[:duration_ms],
          explicit:        track[:explicit],
          isrc:            track[:isrc],
          spotify_url:     track[:spotify_url],
          spotify_id:      track[:spotify_id],
          apple_music_url: apple&.dig(:apple_music_url),
          apple_music_id:  apple&.dig(:apple_music_id)
        )
      end
    rescue Http::SpotifyAuthError, Http::SpotifyApiError => e
      Rails.logger.error("SearchTracks failed: #{e.message}")
      []
    end

    private

    def apple_isrc_lookup(isrc_album_map)
      AppleMusic::Services::CatalogSearcher.new.search_by_isrc_batch(isrc_album_map)
    rescue => e
      Rails.logger.error("Apple Music ISRC lookup failed: #{e.message}")
      {}
    end
  end
end
