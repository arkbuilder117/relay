module Spotify
  module Services
    class AuthService
      def self.fresh_token(spotify_account_record)
        return spotify_account_record.access_token unless spotify_account_record.token_expires_at <= 5.minutes.from_now

        response = exchange_refresh_token(spotify_account_record.refresh_token)
        spotify_account_record.update!(
          access_token:     response["access_token"],
          token_expires_at: Time.current + response["expires_in"].seconds
        )
        spotify_account_record.access_token
      end

      private_class_method def self.exchange_refresh_token(refresh_token)
        conn = Faraday.new("https://accounts.spotify.com") do |f|
          f.request :url_encoded
          f.response :json
        end
        resp = conn.post("/api/token") do |req|
          req.headers["Authorization"] = "Basic #{Base64.strict_encode64("#{ENV['SPOTIFY_CLIENT_ID']}:#{ENV['SPOTIFY_CLIENT_SECRET']}")}"
          req.body = { grant_type: "refresh_token", refresh_token: refresh_token }
        end
        resp.body
      end
    end
  end
end
