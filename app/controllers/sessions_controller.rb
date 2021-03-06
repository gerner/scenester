class SessionsController < ApplicationController
  before_filter :require_user, :only => [:show]

  def create
    auth = request.env['omniauth.auth']
    unless @auth = Authorization.find_from_hash(auth)
      # Create a new user or add an auth to existing user, depending on
      # whether there is already a user signed in.
      # TODO: for now we don't want to allow creation of new users
      # @auth = Authorization.create_from_hash(auth, current_user)
      flash[:notice] = "We're not currently allowing new users to sign up. But you can still use our site to find things to do without having an account!"
      redirect_back_or_default("/")
      return
    end
    # Log the authorizing user in.
    self.current_user = @auth.user

    flash[:notice] = "Successfully logged in"
    redirect_back_or_default(profile_url)
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = "Logged out"
    redirect_back_or_default(profile_url)
  end

  def show
    @user = current_user
  end
end
