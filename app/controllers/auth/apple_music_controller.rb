module Auth
  class AppleMusicController < ApplicationController
    before_action :require_login

    def create
      token      = params.require(:music_user_token)
      storefront = params.fetch(:storefront, "us")

      account = AppleMusicAccount.find_or_initialize_by(user_id: current_user.id)
      account.update!(music_user_token: token, storefront: storefront)
      redirect_to connect_migrations_path(direction: session[:migration_direction]),
                  notice: "Apple Music connected!"
    end

    def destroy
      AppleMusicAccount.where(user_id: current_user.id).destroy_all
      redirect_to connect_migrations_path(direction: session[:migration_direction])
    end
  end
end
