module Catalog
  module ValueObjects
    TrackResult = Struct.new(
      :title, :artist, :album,
      :artwork_url, :duration_ms, :explicit,
      :isrc,
      :spotify_url, :spotify_id,
      :apple_music_url, :apple_music_id,
      keyword_init: true
    ) do
      def on_spotify?      = spotify_id.present?
      def on_apple_music?  = apple_music_id.present?

      def duration_formatted
        return "--:--" unless duration_ms
        total = duration_ms / 1000
        "%d:%02d" % [ total / 60, total % 60 ]
      end
    end
  end
end
