class SearchesController < ApplicationController

  before_filter :load_discount_codes
  before_filter :load_tags, :only => [:new, :show]

  def new
    authorize! :view, Search
    @search = Search.new(params[:search])
    @membership_types = current_user.current_organization.membership_types.all
    @pass_types       = current_user.current_organization.pass_types.all
    prepare_form
  end

  def create
    authorize! :create, Search
    @search = Search.new(params[:search])
    @search.organization_id = current_user.current_organization.id
    @search.save!
    redirect_to @search
  end

  def show
    @search = Search.find(params[:id])
    authorize! :view, @search
    @segment = Segment.new
    @membership_types = current_user.current_organization.membership_types.all
    @pass_types       = current_user.current_organization.pass_types.all
    session[:return_to] ||= request.referer # Record the current page, in case creating a list segment fails.
    prepare_form
    prepare_people
    respond_to do |format|
      format.html { @people = @people.paginate(:page => params[:page], :per_page => (params[:per_page] || 20)) }
      format.csv  { render :csv => Person.where(:id => @people.collect(&:id)).includes(:phones, :address, :tags).order('lower(people.last_name)'), :filename => "#{@search.id}-#{DateTime.now.strftime("%m-%d-%y")}" }
    end
  end

  def tag
    @search = Search.find(params[:id])
    authorize! :tag, Segment
    @search.tag(params[:name])
    flash[:notice] = "We're tagging all the people and we'll be done shortly.  Refresh this page in a minute or two."
    redirect_to @search
  end

  private

    def prepare_form
      @event_options = Event.options_for_select_by_organization(@current_user.current_organization)
      @event_options.unshift(["Any Event", Search::ANY_EVENT])
    end

    def prepare_people
      @people = @search.people
    end

    def load_discount_codes
      @discount_codes = Discount.where(:organization_id => current_user.current_organization).all.map(&:code)
      @discount_codes << Discount::ALL_DISCOUNTS_STRING
      @discount_codes_string = "\"" + @discount_codes.join("\",\"") + "\""
    end
end
