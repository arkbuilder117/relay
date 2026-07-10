module Spotify
  module Services
    class PlaylistFetcher
      def initialize(access_token, spotify_id)
        @client     = Http::SpotifyClient.new(access_token)
        @spotify_id = spotify_id
      end

      def fetch_all
        playlists = []
        url = "/v1/me/playlists?limit=50"

        loop do
          data = @client.get(url)
          data["items"].each do |item|
            next unless item.dig("owner", "id") == @spotify_id
            playlists << Spotify::Entities::SpotifyPlaylist.new(
              id:          item["id"],
              name:        item["name"],
              track_count: item.dig("items", "total") || 0,
              image_url:   item.dig("images", 0, "url")
            )
          end
          break unless data["next"]
          url = data["next"].sub("https://api.spotify.com", "")
        end

        playlists
      end
    end
  end
end
