class MembershipCompsController < ArtfullyOseController
  requires_kit :membership
  
  def new
    @membership_types = current_organization.membership_types.all
    @membership_types_hash = {}
    @membership_types.each {|mt| @membership_types_hash[mt.id] = {:allow_multiple_memberships => mt.allow_multiple_memberships?,:formatted_ends_at => I18n.l(mt.ends_at, :format => :date_for_input)}}

    @membership_comp = MembershipComp.new
    @membership_comp.membership_type             ||= @membership_types.first
    @membership_comp.ends_at                     ||= I18n.l(@membership_types.first.ends_at, :format => :date_for_input)
    @membership_comp.send_email                  ||= true
    @membership_comp.number_of_memberships       ||= 1
    @membership_comp.person_id                    = params[:person_id]
    @membership_comp.segment_id                    = params[:segment_id]
    @membership_comp.search_id                    = params[:search_id]
    @membership_comp.people = find_people
  end

  def index
    @membership_comp = MembershipComp.new
    @membership_comp.membership_type = current_user.current_organization.membership_types.first
    render "create" and return
  end

  def create
    @membership_comp = from_params(params)
    if params[:membership_comp][:confirm].present?
      @membership_comp.benefactor = current_user
      @membership_comp.award
      render 'create' and return
    else
      unless params[:membership_comp][:membership_type].present?
        flash[:error] = "Please select a membership type"
        redirect_to :back and return
      end

      @number_without_emails  =  @membership_comp.people.select{ |person| person.email.blank? }.length
      @number_of_companies    =  @membership_comp.people.select{ |person| person.company? }.length
      @email_preview          =  generate_invitation_preview_for(@membership_comp)
      if !@membership_comp.valid?
        flash[:error] = @membership_comp.errors.full_messages.to_sentence
        redirect_to :back and return 
      end
      render "confirm" and return
    end
  end

  private 
    def generate_invitation_preview_for(membership_comp)
      @resource = Member.new
      render_to_string( :partial    => 'members/mailer/invitation_body', 
                        :layout     => false,
                        :locals     => {:resource => @resource, 
                                        :person => membership_comp.people.first,
                                        :welcome_message => membership_comp.welcome_message,
                                        :membership_types => [membership_comp.membership_type],
                                        :invitation_token => "",
                                        :organization => current_user.current_organization})

    end

    def from_params(params)
      membership_comp                       = MembershipComp.new
      membership_comp_params                = params[:membership_comp]
      membership_comp.membership_type       = MembershipType.find(membership_comp_params[:membership_type]) if membership_comp_params[:membership_type].present?
      membership_comp.ends_at               = membership_comp_params[:ends_at]
      membership_comp.send_email            = membership_comp_params[:send_email] == "true"
      membership_comp.number_of_memberships = membership_comp_params[:number_of_memberships]
      membership_comp.welcome_message       = membership_comp_params[:welcome_message]
      membership_comp.notes                 = membership_comp_params[:notes]
      membership_comp.person_id             = membership_comp_params[:person_id]
      membership_comp.search_id             = membership_comp_params[:search_id]
      membership_comp.segment_id            = membership_comp_params[:segment_id]

      membership_comp.organization          = current_user.current_organization
      membership_comp.people                = find_people(membership_comp_params)
      membership_comp
    end

    def cache_key
      current_user.id.to_s + "membership_comp_person_ids"
    end

    def find_people(p = params)

      return @people unless @people.nil?

      if p[:person_id].present?
        @ids = Array.wrap(p[:person_id])
      elsif p[:segment_id].present?
        @ids = current_user.current_organization.segments.where(:id => p[:segment_id]).first.people.collect(&:id)
      elsif p[:search_id].present?
        @ids = current_user.current_organization.searches.where(:id => p[:search_id]).first.people.collect(&:id)
      else
        []
      end

      @people = Array.wrap(Person.find(@ids))
      @people
    end
end