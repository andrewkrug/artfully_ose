class Members::SessionsController < Devise::SessionsController
  layout 'devise_layout'

  def new
    # Store the referrer so we can send them back
    # where they started after successful sign in.
    session[:continue] = request.referrer
    super
  end

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || session.delete(:continue) || signed_in_root_path(resource_or_scope)
  end
end