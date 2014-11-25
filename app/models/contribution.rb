class Contribution
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_accessor :contributor, 
                :person_id, 
                :subtype,         #Monetary, In-kind  
                :payment_method,  #Cash, Check, Credit card, Other
                :occurred_at, 
                :details, 
                :organization_id, 
                :creator_id, 
                :order, 
                :action
              
  #
  # Standard for the app is (total_donation_amount = amount + nongift_amount)
  # For example, if someone wrote a check for $100 for event with $25 FMV, amount = $75 and nongift_amount = $25
  #
  attr_accessor :amount, 
                :nongift_amount

  set_watch_for :occurred_at, :local_to => :organization

  def initialize(params = {})
    load(params)
    @contributor = find_contributor
  end
  
  #hacks to make form_for work
  def id
    self.order.try(:id)
  end
  
  def persisted?
    !self.order.nil? && self.order.persisted?
  end
  
  def organization
    @organization ||= Organization.find(self.organization_id)
  end
  
  def self.for(order)  
    action = GiveAction.where(:subject_id => order.id).where(:subject_type => "Order").first
    Contribution.new.tap do |contribution|
      contribution.order            = order
      contribution.contributor      = order.person
      contribution.occurred_at      = order.created_at
      contribution.amount           = order.items.first.price
      contribution.nongift_amount   = order.items.first.nongift_amount
      contribution.payment_method   = order.payment_method
      
      contribution.subtype          = action.subtype
      contribution.details          = action.details
      contribution.organization_id  = order.organization_id
      contribution.creator_id       = action.creator_id
      contribution.action           = action
      contribution.person_id        = contribution.contributor.id
    end
  end

  def save(order_klass = ApplicationOrder, &block)
    @order  = build_order(order_klass)
    Order.transaction do
      @order.save!
      @order.update_attribute(:created_at, @occurred_at)      
      @item   = build_item(@order, @amount, @nongift_amount)
      @item.save!
      
      @action = build_action
      @action.save!
    end
    yield(self) if block_given?
    @order
  end

  def has_contributor?
    contributor.present?
  end
  
  def update(new_contribution)
    order = self.order
    item = self.order.items.first
    action = self.action
    
    item.price            = new_contribution.amount
    item.nongift_amount   = new_contribution.nongift_amount
    item.realized_price   = new_contribution.amount
    item.net              = new_contribution.amount
  
    action.details        = new_contribution.details
    action.subtype        = new_contribution.subtype
    
    order.created_at      = new_contribution.occurred_at
    order.payment_method  = new_contribution.payment_method
    order.details         = new_contribution.details
    
    ActiveRecord::Base.transaction do
      item.save
      order.save
      action.save
    end
    
    true
  end

  private

  def load(params)
    @subtype         = params[:subtype]
    @payment_method  = params[:payment_method]
    @amount          = params[:amount]
    @nongift_amount  = params[:nongift_amount]
    @organization_id = params[:organization_id]
    @occurred_at     = ActiveSupport::TimeZone.create(Organization.find(@organization_id).time_zone).parse(params[:occurred_at]) if params[:occurred_at].present?
    @details         = params[:details]
    @person_id       = params[:person_id]
    @creator_id      = params[:creator_id]
  end

  def find_contributor
    Person.find(@person_id) unless @person_id.blank?
  end

  def build_action
    person = Person.find(@person_id)
    action = GiveAction.for_organization(self.organization)

    action.occurred_at = @occurred_at
    action.subtype = @subtype
    action.details = @details

    action.person = person
    action.subject = person
    
    action.creator_id = @creator_id
    action.subject = @order
    action
  end

  def build_order(order_klass = ApplicationOrder)
    attributes = {
      :person_id       => @person_id,
      :organization_id => @organization_id,
      :details         => @details
    }

    order = order_klass.new(attributes).tap do |order|
      order.payment_method = @payment_method
      order.skip_actions = true
      order.skip_email = true
    end
  end

  def build_item(order, price, nongift_amount = 0)
    nongift_amount ||= 0
    Item.new({
      :order_id       => order.id,
      :product_type   => "Donation",
      :state          => "settled",
      :price          => price,
      :nongift_amount => nongift_amount,
      :realized_price => price,
      :net            => price
    })
  end
end