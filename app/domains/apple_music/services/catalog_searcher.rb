module AppleMusic
  module Services
    class CatalogSearcher
      BATCH_SIZE = 25
      STOREFRONT = "us"

      def initialize
        dev_token = DeveloperTokenService.fetch_token
        @client   = Http::AppleMusicClient.new(dev_token)
      end

      def search(query, limit: 10)
        encoded = URI.encode_www_form_component(query)
        data    = @client.get("/v1/catalog/#{STOREFRONT}/search?term=#{encoded}&types=songs&limit=#{limit}")
        (data.dig("results", "songs", "data") || []).map { |item| map_item(item) }
      end

      def search_by_isrc_batch(isrc_album_map)
        candidates = Hash.new { |h, k| h[k] = [] }

        isrc_album_map.keys.compact.each_slice(BATCH_SIZE) do |batch|
          data = @client.get("/v1/catalog/#{STOREFRONT}/songs?filter[isrc]=#{batch.join(',')}")
          (data["data"] || []).each do |item|
            mapped = map_item(item)
            candidates[mapped[:isrc]] << mapped if mapped[:isrc]
          end
        end

        candidates.transform_values do |matches|
          preferred_album = isrc_album_map[matches.first[:isrc]]
          best_match(matches, preferred_album)
        end
      end

      private

      def best_match(matches, preferred_album)
        return matches.first if preferred_album.blank? || matches.one?

        normalized = preferred_album.downcase
        matches.find { |m| m[:album]&.downcase == normalized } ||
          matches.find { |m| m[:album]&.downcase&.include?(normalized) } ||
          matches.first
      end

      def map_item(item)
        attrs   = item["attributes"] || {}
        artwork = attrs["artwork"] || {}
        url     = artwork["url"]&.gsub("{w}", "300")&.gsub("{h}", "300")

        {
          isrc:             attrs["isrc"],
          title:            attrs["name"],
          artist:           attrs["artistName"],
          album:            attrs["albumName"],
          duration_ms:      attrs["durationInMillis"],
          explicit:         attrs["contentRating"] == "explicit",
          apple_music_url:  attrs["url"],
          apple_music_id:   item["id"],
          artwork_url:      url
        }
      end
    end
  end
end
