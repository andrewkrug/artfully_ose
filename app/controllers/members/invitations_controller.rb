class Members::InvitationsController < Devise::InvitationsController
  layout 'devise_layout'

  def after_accept_path_for(resource)
    members_root_path
  end
end