class Migration < ApplicationRecord
  belongs_to :user
  has_many :playlist_results, class_name: "MigrationPlaylistResult", dependent: :destroy

  validates :direction, presence: true, inclusion: { in: %w[spotify_to_apple apple_to_spotify] }
  validates :status, presence: true

  def match_percentage
    return 0 if total_tracks.zero?
    ((matched_tracks.to_f / total_tracks) * 100).round
  end

  def spotify_to_apple? = direction == "spotify_to_apple"
  def apple_to_spotify? = direction == "apple_to_spotify"
  def pending?          = status == "pending"
  def in_progress?      = status == "in_progress"
  def completed?        = status == "completed"
  def failed?           = status == "failed"
end
