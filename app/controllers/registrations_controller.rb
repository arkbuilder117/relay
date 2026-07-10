class RegistrationsController < ApplicationController
  def new; end

  def create
    user = User.create!(
      email:                 params.require(:email).to_s.downcase,
      password:              params.require(:password),
      password_confirmation: params.require(:password_confirmation)
    )
    session[:user_id] = user.id
    redirect_to root_path, notice: "Account created!"
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end
end
