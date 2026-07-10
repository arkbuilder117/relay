module Spotify
  module Services
    class LikedSongsSaver
      BATCH_SIZE = 50

      def initialize(access_token)
        @client = Http::SpotifyClient.new(access_token)
      end

      def save(track_ids)
        track_ids.each_slice(BATCH_SIZE) do |batch|
          @client.put("/v1/me/tracks", { ids: batch })
        end
      end
    end
  end
end
