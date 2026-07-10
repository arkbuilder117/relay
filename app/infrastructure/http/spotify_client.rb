module Http
  class SpotifyClient
    BASE_URL = "https://api.spotify.com"

    def initialize(access_token)
      @conn = Faraday.new(BASE_URL) do |f|
        f.request :retry, max: 3, interval: 0.5, backoff_factor: 2,
                          exceptions: [ Faraday::TimeoutError, Faraday::ConnectionFailed ]
        f.response :json
        f.headers["Authorization"] = "Bearer #{access_token}"
        f.headers["Content-Type"]  = "application/json"
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

    def put(path, body = {})
      response = @conn.put(path) { |req| req.body = body.to_json }
      handle_response(response)
    end

    private

    def handle_response(response)
      case response.status
      when 200, 201 then response.body
      when 401 then raise Http::SpotifyAuthError, "Spotify token invalid or expired"
      when 403 then raise Http::SpotifyForbiddenError, "Spotify access forbidden: #{response.env.url}"
      when 429 then raise Http::SpotifyRateLimitError, "Spotify rate limit exceeded"
      else raise Http::SpotifyApiError, "Spotify API error #{response.status}: #{response.env.url}"
      end
    end
  end

  class SpotifyAuthError      < StandardError; end
  class SpotifyForbiddenError < StandardError; end
  class SpotifyRateLimitError < StandardError; end
  class SpotifyApiError       < StandardError; end
end
