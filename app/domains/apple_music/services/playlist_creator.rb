module AppleMusic
  module Services
    class PlaylistCreator
      TRACK_BATCH_SIZE = 100

      def initialize(apple_music_account)
        dev_token = AppleMusic::Services::DeveloperTokenService.fetch_token
        @client   = Http::AppleMusicClient.new(dev_token, apple_music_account.music_user_token)
      end

      def create(name:, track_ids:)
        body = {
          attributes:    { name: name },
          relationships: { tracks: { data: [] } }
        }
        response    = @client.post("/v1/me/library/playlists", body)
        playlist_id = response.dig("data", 0, "id")

        track_ids.each_slice(TRACK_BATCH_SIZE) do |batch|
          track_data = batch.map { |id| { id: id, type: "songs" } }
          @client.post("/v1/me/library/playlists/#{playlist_id}/tracks", { data: track_data })
          sleep 0.34
        end

        playlist_id
      end
    end
  end
end
