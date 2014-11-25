class Store::RetrievalsController < Store::StoreController
  def index

  end

  def create
    @person = @store_organization.people.where(:email => params[:email]).first

    return fail if @person.nil?

    @passes = Pass.where(:organization_id => @store_organization.id)
                    .where(:person_id => @person.id)
                    .not_expired
                    .all
    
    return fail if @passes.empty?

    @person.delay.send_pass_summary_email(@passes)

    flash[:notice] = "Your reminder has been sent"
    render "index"
  end

  private
    def fail
      flash[:error] = "We couldn't send a reminder email because we can't find your pass. If you think this is an error then please email us at #{@store_organization.email}"
      render "index"
    end
end