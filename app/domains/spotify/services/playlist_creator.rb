module Spotify
  module Services
    class PlaylistCreator
      TRACK_BATCH_SIZE = 100

      def initialize(access_token, spotify_id)
        @client     = Http::SpotifyClient.new(access_token)
        @spotify_id = spotify_id
      end

      def create(name:, track_ids:)
        response    = @client.post("/v1/users/#{@spotify_id}/playlists", { name: name, public: false })
        playlist_id = response["id"]

        track_ids.each_slice(TRACK_BATCH_SIZE) do |batch|
          uris = batch.map { |id| "spotify:track:#{id}" }
          @client.post("/v1/playlists/#{playlist_id}/items", { uris: uris })
        end

        playlist_id
      end
    end
  end
end
