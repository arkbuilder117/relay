module Spotify
  module Services
    class TrackFetcher
      def initialize(access_token)
        @client = Http::SpotifyClient.new(access_token)
      end

      def fetch_all(playlist_id)
        tracks = []
        url = "/v1/playlists/#{playlist_id}/items?limit=50"

        loop do
          data = @client.get(url)
          data["items"].each do |item|
            next if item.nil?
            content = item["item"] || item["track"]
            next if content.nil? || content["id"].nil?
            next unless content["type"] == "track"
            tracks << Spotify::Mappers::TrackMapper.from_api(item)
          end
          break unless data["next"]
          url = data["next"].sub("https://api.spotify.com", "")
        end

        tracks
      end
    end
  end
end
