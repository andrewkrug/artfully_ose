class Mobile::UsersController < ApplicationController
  skip_before_filter :authenticate_user!, :only => :sign_in

  def sign_in
    user = User.find_by_email(params[:email])

    if user && user.valid_password?(params[:password])

      if user.organizations.empty?
        error = {
          :error => "Could not sign in",
          :reason => "User is not a member of any organizations",
          :code => 2
        }
        render :json => error, :status => 422 and return
      end

      now = Time.parse(params[:now]) rescue Time.zone.now

      render :json => user, :auth_token => true, :organization => user.organizations.first, :now => now
    else
      error = {
        :error => "Could not sign in",
        :reason => "Invalid email/password",
        :code => 1
      }
      render :json => error, :status => 422
    end
  end
end
