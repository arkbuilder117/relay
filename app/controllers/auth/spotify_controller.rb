module Auth
  class SpotifyController < ApplicationController
    before_action :require_login, except: :failure

    def callback
      if params[:error]
        redirect_to connect_migrations_path(direction: session[:migration_direction])
        return
      end

      auth    = request.env["omniauth.auth"]
      Rails.logger.info "[Spotify OAuth] credentials: #{auth.credentials.to_h.inspect}"
      Rails.logger.info "[Spotify OAuth] extra: #{auth.extra.to_h.inspect}"
      account = SpotifyAccount.find_or_initialize_by(user_id: current_user.id)
      account.update!(
        spotify_id:       auth.uid,
        display_name:     auth.info.name,
        access_token:     auth.credentials.token,
        refresh_token:    auth.credentials.refresh_token,
        token_expires_at: Time.at(auth.credentials.expires_at)
      )
      redirect_to connect_migrations_path(direction: session[:migration_direction]),
                  notice: "Spotify connected!"
    end

    def failure
      redirect_to connect_migrations_path(direction: session[:migration_direction])
    end

    def destroy
      SpotifyAccount.where(user_id: current_user.id).destroy_all
      redirect_to connect_migrations_path(direction: session[:migration_direction])
    end
  end
end
