class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?

  private

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = session[:user_id] ? User.find(session[:user_id]) : nil
  rescue ActiveRecord::RecordNotFound
    session.delete(:user_id)
    @current_user = nil
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless logged_in?
      session[:return_to] = request.url
      redirect_to new_session_path, alert: "Please sign in."
    end
  end
end
