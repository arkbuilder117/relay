module AppleMusic
  module Services
    class FavoritedSongsSaver
      BATCH_SIZE = 25

      def initialize(apple_music_account)
        dev_token = AppleMusic::Services::DeveloperTokenService.fetch_token
        @client   = Http::AppleMusicClient.new(dev_token, apple_music_account.music_user_token)
      end

      def save(catalog_song_ids)
        catalog_song_ids.each_slice(BATCH_SIZE) do |batch|
          @client.post("/v1/me/favorites?ids[songs]=#{batch.join(',')}", {})
          sleep 0.34
        end
      end
    end
  end
end
