module Spotify
  module Services
    class ClientCredentialsService
      TOKEN_URL = "https://accounts.spotify.com/api/token"
      CACHE_KEY = "spotify_client_credentials_token"

      def self.fetch_token
        Rails.cache.fetch(CACHE_KEY, expires_in: 55.minutes) do
          new.generate
        end
      end

      def generate
        conn = Faraday.new do |f|
          f.response :json
        end

        credentials = Base64.strict_encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}")

        response = conn.post(TOKEN_URL) do |req|
          req.headers["Authorization"] = "Basic #{credentials}"
          req.headers["Content-Type"]  = "application/x-www-form-urlencoded"
          req.body = "grant_type=client_credentials"
        end

        raise Http::SpotifyAuthError, "Failed to get client credentials token" unless response.status == 200
        response.body["access_token"]
      end
    end
  end
end
