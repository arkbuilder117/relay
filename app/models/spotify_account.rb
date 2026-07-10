class SpotifyAccount < ApplicationRecord
  belongs_to :user

  encrypts :access_token
  encrypts :refresh_token

  validates :spotify_id, :access_token, :refresh_token, :token_expires_at, presence: true

  def token_near_expiry? = token_expires_at <= 5.minutes.from_now
end
