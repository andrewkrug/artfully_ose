class MembershipType < ActiveRecord::Base
  include Ext::Integrations::ServiceFee
  extend ::ArtfullyOseHelper
  attr_accessible :name, :price, :fee, :number_of_shows, 
                  :plan, :on_sale, :description, :ends_at, 
                  :starts_at, :duration, :type, :period, :number_of_tickets, :sales_start_at, :sales_end_at,
                  :thanks_copy, :invitation_email_text_copy, :hide_fee, :renewal_price, :offer_renewal,
                  :limit_per_transaction

  belongs_to :organization
  has_many :memberships
  has_many :members, :through => :memberships
  belongs_to :segment

  after_create :create_list_segment
  
  validates :name, :description, :price, :presence => true

  scope :storefront, where(:on_sale => true)
  scope :on_sale, where(:on_sale => true)
  scope :sales_valid, where("sales_start_at < ? or sales_start_at is null", DateTime.now).where("sales_end_at > ? or sales_end_at is null", DateTime.now)
  scope :not_ended, where('ends_at > ?', DateTime.now)

  comma do
    name
    description
    price                      { |price| MembershipType.number_as_cents price }
    type
    memberships 'Memberships sold' do |m|
      m.count
    end
    members { |m| m.distinct(:member_id).count }
    duration
    period
    starts_at
    ends_at
    on_sale
    sales_start_at
    sales_end_at
  end

  def self.in_play(organization)
    self.find((organization.membership_types.not_ended.pluck(:id).uniq + organization.memberships.current.select(:membership_type_id).uniq.pluck(:membership_type_id)))
  end

  def membershipize
    self.name.end_with?("Membership") ? self.name : self.name + " Membership"
  end

  def price_for(member = nil)
    return price if member.nil?

    (offer_renewal? && member.current?) ? renewal_price : price
  end

  def create_list_segment
    @search = organization.searches.create({:membership_type => self})
    @segment = organization.segments.create({:search => @search, :name => self.name})
    self.segment = @segment
    save
  end

  def allow_multiple_memberships?
    self.limit_per_transaction > 1
  end
end