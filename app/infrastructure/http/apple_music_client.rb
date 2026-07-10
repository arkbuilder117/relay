module Http
  class AppleMusicClient
    BASE_URL = "https://api.music.apple.com"

    def initialize(developer_token, music_user_token = nil)
      @conn = Faraday.new(BASE_URL) do |f|
        f.request :retry, max: 3, interval: 0.5, backoff_factor: 2,
                          exceptions: [ Faraday::TimeoutError, Faraday::ConnectionFailed ]
        f.response :json
        f.headers["Authorization"] = "Bearer #{developer_token}"
        f.headers["Music-User-Token"] = music_user_token if music_user_token
        f.headers["Content-Type"]     = "application/json"
      end
    end

    def get(path)
      response = @conn.get(path)
      handle_response(response)
    end

    def post(path, body = {})
      response = @conn.post(path) { |req| req.body = body.to_json }
      handle_response(response)
    end

    private

    def handle_response(response)
      case response.status
      when 200, 201, 202 then response.body
      when 204 then nil
      when 401 then raise Http::AppleMusicAuthError, "Apple Music token invalid or revoked"
      when 429 then raise Http::AppleMusicRateLimitError, "Apple Music rate limit exceeded"
      else raise Http::AppleMusicApiError, "Apple Music API error #{response.status}"
      end
    end
  end

  class AppleMusicAuthError      < StandardError; end
  class AppleMusicRateLimitError < StandardError; end
  class AppleMusicApiError       < StandardError; end
end
