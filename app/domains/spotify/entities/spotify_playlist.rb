module Spotify
  module Entities
    class SpotifyPlaylist
      attr_reader :id, :name, :track_count, :image_url

      def initialize(id:, name:, track_count: 0, image_url: nil)
        @id          = id
        @name        = name
        @track_count = track_count
        @image_url   = image_url
      end
    end
  end
end
