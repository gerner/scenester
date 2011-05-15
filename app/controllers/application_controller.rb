class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :set_timezone

  def set_timezone
    # current_user.time_zone #=> 'London'
    #Time.zone = current_user.time_zone
    Time.zone = "America/Los_Angeles"
  end

  protected

  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to login_url
      return false
    end
  end

  def current_user
    @current_user ||= User.find_by_id(session[:user_id])
  end

  def signed_in?
    !!current_user
  end

  helper_method :current_user, :signed_in?

  def current_user=(user)
    @current_user = user
    session[:user_id] = user.id
  end

  def store_location
    session[:return_to] = request.request_uri if request.get? and controller_name != "sessions"
  end

  def redirect_back_or_default(default)
    if session[:return_to]
      return_to = session[:return_to]
      session[:return_to] = nil
      redirect_to return_to
    else
      redirect_to default
    end
  end
end
