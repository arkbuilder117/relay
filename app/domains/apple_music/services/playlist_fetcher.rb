module AppleMusic
  module Services
    class PlaylistFetcher
      def initialize(apple_music_account)
        dev_token   = AppleMusic::Services::DeveloperTokenService.fetch_token
        @client     = Http::AppleMusicClient.new(dev_token, apple_music_account.music_user_token)
        @storefront = apple_music_account.storefront
      end

      def fetch_all
        playlists = []
        url = "/v1/me/library/playlists?limit=100&include=tracks"

        loop do
          data = @client.get(url)
          (data["data"] || []).each do |item|
            playlists << AppleMusic::Entities::AppleMusicPlaylist.new(
              id:          item["id"],
              name:        item.dig("attributes", "name"),
              track_count: item.dig("relationships", "tracks", "meta", "total") ||
                             item.dig("relationships", "tracks", "data")&.length || 0,
              image_url:   item.dig("attributes", "artwork", "url")
            )
          end
          next_url = data.dig("next")
          break unless next_url
          url = next_url
        end

        playlists
      end
    end
  end
end
