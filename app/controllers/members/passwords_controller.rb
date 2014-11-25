class Members::PasswordsController < Devise::PasswordsController
  layout 'devise_layout'

  protected
    
    #This method changed from devise 2.0 and 3.0
    def after_sign_in_path_for(resource)
      members_root_path
    end
end