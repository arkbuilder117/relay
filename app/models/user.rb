class User < ApplicationRecord
  has_secure_password

  has_one  :spotify_account,     dependent: :destroy
  has_one  :apple_music_account, dependent: :destroy
  has_many :migrations,          dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
end
