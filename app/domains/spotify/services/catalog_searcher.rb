module Spotify
  module Services
    class CatalogSearcher
      def initialize
        token   = ClientCredentialsService.fetch_token
        @client = Http::SpotifyClient.new(token)
      end

      def search(query, limit: 10)
        encoded = URI.encode_www_form_component(query)
        data    = @client.get("/v1/search?q=#{encoded}&type=track&limit=#{limit}")
        (data.dig("tracks", "items") || []).map { |item| map_item(item) }
      end

      private

      def map_item(item)
        {
          title:       item["name"],
          artist:      item.dig("artists", 0, "name") || "",
          album:       item.dig("album", "name"),
          artwork_url: item.dig("album", "images", 0, "url"),
          duration_ms: item["duration_ms"],
          explicit:    item["explicit"],
          isrc:        item.dig("external_ids", "isrc"),
          spotify_url: item.dig("external_urls", "spotify"),
          spotify_id:  item["id"]
        }
      end
    end
  end
end
