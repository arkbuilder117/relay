class SessionsController < ApplicationController
  def new; end

  def create
    user = Identity::Services::AuthenticationService.new.authenticate(
      email:    params.require(:email),
      password: params.require(:password)
    )
    if user
      session[:user_id] = user.id
      redirect_to root_path, notice: "Welcome back!"
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to new_session_path, notice: "Signed out."
  end
end
