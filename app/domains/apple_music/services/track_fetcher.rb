module AppleMusic
  module Services
    class TrackFetcher
      def initialize(apple_music_account)
        dev_token = AppleMusic::Services::DeveloperTokenService.fetch_token
        @client   = Http::AppleMusicClient.new(dev_token, apple_music_account.music_user_token)
      end

      def fetch_all(playlist_id)
        tracks = []
        url = "/v1/me/library/playlists/#{playlist_id}/tracks?limit=100"

        loop do
          data = @client.get(url)
          (data["data"] || []).each do |item|
            tracks << AppleMusic::Mappers::TrackMapper.from_api(item)
          end
          next_url = data.dig("next")
          break unless next_url
          url = next_url
        end

        tracks
      end
    end
  end
end
