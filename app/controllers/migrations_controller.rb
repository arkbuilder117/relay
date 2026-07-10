class MigrationsController < ApplicationController
  before_action :require_login

  def index
    @spotify_connected     = SpotifyAccount.find_by(user_id: current_user.id)
    @apple_music_connected = AppleMusicAccount.find_by(user_id: current_user.id)
  end

  def connect
    session[:migration_direction] = params[:direction]
    @direction             = params[:direction]
    @spotify_connected     = SpotifyAccount.find_by(user_id: current_user.id)
    @apple_music_connected = AppleMusicAccount.find_by(user_id: current_user.id)
    @developer_token       = AppleMusic::Services::DeveloperTokenService.fetch_token
  rescue StandardError
    @developer_token = ""
  end

  def playlists
    @direction = session[:migration_direction]
    @playlists = UseCases::FetchUserPlaylists.new.call(user: current_user, direction: @direction)
  end

  def create
    direction           = params.require(:direction)
    playlist_ids        = params.fetch(:playlist_ids, [])
    include_liked_songs = params[:include_liked_songs] == "1"

    migration = UseCases::StartMigration.new.call(
      user:                current_user,
      direction:           direction,
      playlist_ids:        playlist_ids,
      include_liked_songs: include_liked_songs
    )

    redirect_to migration_path(migration.id)
  rescue StandardError => e
    redirect_to playlists_migrations_path(direction: direction), alert: e.message
  end

  def retry
    @migration = current_user.migrations.find(params[:id])

    unless @migration.status.in?(%w[failed pending])
      return redirect_to migration_path(@migration), alert: "Only failed or pending migrations can be retried."
    end

    @migration.update!(status: "pending", failure_reason: nil)
    MigrationJob.perform_later(@migration.id)

    redirect_to migration_path(@migration)
  end

  def history
    @migrations = current_user.migrations.order(created_at: :desc)
  end

  def show
    @migration = current_user.migrations.includes(playlist_results: :track_results).find(params[:id])
    @playlists = @migration.playlist_results.to_a
    @presenter = Presenters::MigrationPresenter.new(@migration)
  end
end
