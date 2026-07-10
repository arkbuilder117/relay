module Spotify
  module Services
    class TrackSearcher
      def initialize(access_token)
        @client = Http::SpotifyClient.new(access_token)
      end

      def search_by_isrc(isrc)
        data = @client.get("/v1/search?q=isrc:#{isrc}&type=track&limit=1")
        item = data.dig("tracks", "items", 0)
        return nil unless item
        Spotify::Mappers::TrackMapper.from_api(item)
      end

      def search_by_title_artist(title, artist)
        query = URI.encode_www_form_component("track:#{title} artist:#{artist}")
        data  = @client.get("/v1/search?q=#{query}&type=track&limit=1")
        item  = data.dig("tracks", "items", 0)
        return nil unless item
        Spotify::Mappers::TrackMapper.from_api(item)
      end
    end
  end
end
