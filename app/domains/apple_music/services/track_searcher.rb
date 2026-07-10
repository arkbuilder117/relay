module AppleMusic
  module Services
    class TrackSearcher
      BATCH_SIZE = 25

      def initialize(apple_music_account)
        dev_token   = AppleMusic::Services::DeveloperTokenService.fetch_token
        @client     = Http::AppleMusicClient.new(dev_token, apple_music_account.music_user_token)
        @storefront = apple_music_account.storefront
      end

      def search_by_isrc_batch(isrcs)
        results = {}
        isrcs.each_slice(BATCH_SIZE) do |batch|
          data = @client.get("/v1/catalog/#{@storefront}/songs?filter[isrc]=#{batch.join(',')}")
          (data["data"] || []).each do |item|
            track = AppleMusic::Mappers::TrackMapper.from_api(item)
            next unless track.isrc
            results[track.isrc] ||= []
            results[track.isrc] << track
          end
          sleep 0.34
        end
        results
      end

      def search_by_title_artist(title, artist)
        query = URI.encode_www_form_component("#{title} #{artist}")
        data  = @client.get("/v1/catalog/#{@storefront}/search?term=#{query}&types=songs&limit=1")
        item  = data.dig("results", "songs", "data", 0)
        return nil unless item
        AppleMusic::Mappers::TrackMapper.from_api(item)
      end
    end
  end
end
