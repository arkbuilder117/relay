module AppleMusic
  module Services
    class FavoritedSongsFetcher
      def initialize(apple_music_account)
        @account  = apple_music_account
        dev_token = AppleMusic::Services::DeveloperTokenService.fetch_token
        @client   = Http::AppleMusicClient.new(dev_token, apple_music_account.music_user_token)
      end

      def fetch_all
        playlist = find_favorites_playlist
        return [] unless playlist

        AppleMusic::Services::TrackFetcher.new(@account).fetch_all(playlist["id"])
      end

      private

      def find_favorites_playlist
        url = "/v1/me/library/playlists?limit=100&include=catalog&extend=inFavorites"

        loop do
          data  = @client.get(url)
          found = (data["data"] || []).find do |pl|
            attrs = pl["attributes"] || {}
            attrs["canEdit"] == false && attrs["hasCatalog"] == false && attrs["inFavorites"] == true
          end
          return found if found
          break unless data["next"]
          url = data["next"]
        end

        nil
      end
    end
  end
end
