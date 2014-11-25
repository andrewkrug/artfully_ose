class ArtfullyOseController < ActionController::Base
  include Ext::Integrations::ArtfullyOseController

  protect_from_forgery

  before_filter :authenticate_user!
  layout :specify_layout
  after_filter :set_csrf_cookie_for_angular
  before_filter :require_more_info

  delegate :current_organization, :to => :current_user

  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = "Sorry, we couldn't find that page!"
    redirect_to root_path
  end

  protected

    #
    # don't appent "kit" to the name.
    # Example requires_kit :membership
    #
    def self.requires_kit(kit)
      before_filter do 
        unless current_user.current_organization.has_kit? (kit)
          raise CanCan::AccessDenied
        end
      end
    end

    def to_plural(variable, word)
      self.class.helpers.pluralize(variable, word)
    end

    def specify_layout
      (public_controller? or public_action?) ? 'devise_layout' : 'application'
    end

    def authenticate_inviter!
      authorize! :adminster, :all
      super
    end

    def params_person_id
      params[:person_id] || params[:individual_id] || params[:company_id]
    end

    def redirect_to_person(person, params={})
      if params[:return_to].present?
        redirect_to params[:return_to]
      elsif person.type == "Individual"
        redirect_to individual_url(person)
      elsif person.type == "Company"
        redirect_to company_url(person)
      else
        raise "Undefined type of person saved."
      end
    end

    def verified_request?
      super || form_authenticity_token == request.headers['X_XSRF_TOKEN']
    end

  private

    def load_tags
      @tags = current_user.current_organization.unique_tag_strings_for(:people)
      @tags_string = "\"" + @tags.join("\",\"") + "\""
    end

    def user_requesting_next_step?
      params[:commit].try(:downcase) =~ /next/
    end

    def user_just_uploaded_an_image?
      (params[:event].present? && params[:event][:image].present?) ||
        params[:commit].try(:downcase) =~ /upload/
    end

    def public_controller?
      %w( devise/sessions devise/registrations devise/passwords devise/unlocks ).include?(params[:controller])
    end

    def public_action?
      params[:controller] == "devise/invitations"
    end# app/controllers/application_controller.rb

    def set_csrf_cookie_for_angular
      cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
    end

    def require_more_info
      if need_more_info?
        flash[:info] = "We need to collect more information about your organization before you continue."
        redirect_to collect_info_signups_path
      end
    end

    def keep_page_from_caching
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end
end
