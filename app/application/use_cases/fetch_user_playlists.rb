module UseCases
  class FetchUserPlaylists
    def call(user:, direction:)
      if direction == "spotify_to_apple"
        account = SpotifyAccount.find_by(user_id: user.id)
        raise "Spotify not connected" unless account
        token = Spotify::Services::AuthService.fresh_token(account)
        Spotify::Services::PlaylistFetcher.new(token, account.spotify_id).fetch_all
      else
        account = AppleMusicAccount.find_by(user_id: user.id)
        raise "Apple Music not connected" unless account
        AppleMusic::Services::PlaylistFetcher.new(account).fetch_all
      end
    end
  end
end
