module Spotify
  module Mappers
    class TrackMapper
      def self.from_api(item)
        track = item["item"] || item["track"] || item
        Spotify::Entities::SpotifyTrack.new(
          id:     track["id"],
          title:  track["name"],
          artist: track.dig("artists", 0, "name") || "",
          isrc:   track.dig("external_ids", "isrc"),
          album:  track.dig("album", "name")
        )
      end
    end
  end
end
