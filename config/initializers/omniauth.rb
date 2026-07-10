Rails.application.config.middleware.use OmniAuth::Builder do
  provider :spotify,
           ENV["SPOTIFY_CLIENT_ID"],
           ENV["SPOTIFY_CLIENT_SECRET"],
           scope: "playlist-read-private playlist-read-collaborative"
end

OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning     = true
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
