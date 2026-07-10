class AppleMusicAccount < ApplicationRecord
  belongs_to :user

  encrypts :music_user_token

  validates :music_user_token, :storefront, presence: true
end
