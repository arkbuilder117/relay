module AppleMusic
  module Services
    class DeveloperTokenService
      CACHE_KEY    = "apple_music/developer_token"
      TTL_SECONDS  = 43200 # 12 hours — matches JWT exp

      def self.fetch_token
        Rails.cache.fetch(CACHE_KEY, expires_in: (TTL_SECONDS - 300).seconds) { new.generate }
      end

      def generate
        private_key = OpenSSL::PKey::EC.new(ENV["APPLE_PRIVATE_KEY"])
        headers     = { kid: ENV["APPLE_KEY_ID"], alg: "ES256" }
        payload     = { iss: ENV["APPLE_TEAM_ID"], iat: Time.now.to_i, exp: Time.now.to_i + TTL_SECONDS }
        JWT.encode(payload, private_key, "ES256", headers)
      end
    end
  end
end
