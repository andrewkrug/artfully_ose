class MemberCardsController < ArtfullyOseController
  requires_kit :membership

  before_filter :find_members

  def new
    pdf = MemberCardGenerator::BlanksUsaIdc6.new(@members).generate
    send_data pdf, :filename => "member_cards.pdf", :type => "application/pdf", :disposition => "attachment"
  end

  private
  def find_members
    @members = if params[:search_id].present?
      search = Search.where(:id => params[:search_id]).first
      if search
        load_members search.people.map { |person| person.memberships.current.first.member_id }
      else
        raise CanCan::AccessDenied
      end
    elsif params[:start].present?
      members_from_sales_search
    else
      raise CanCan::AccessDenied
    end
  end

  def load_members(member_ids)
    Member.find Array.wrap(member_ids).flatten
  end

  def members_from_sales_search
    membership_type = MembershipType.find_by_id(params[:membership_type_id]) if params[:membership_type_id].present?
    search          = MembershipSaleSearch.new :start           => params[:start],
                                               :stop            => params[:stop],
                                               :organization    => current_organization,
                                               :membership_type => membership_type

    load_members search.results.map { |order| order.items.select(&:membership?).first.product.member_id }
  end

  def sales_params?
    params[:start].present?
  end
end