class PassType < ActiveRecord::Base
  include Ext::Integrations::ServiceFee
  include OhNoes::Destroy
  extend ::ArtfullyOseHelper
  
  belongs_to :organization
  has_many :passes

  attr_accessible :name, :description, :hide_fee, :thanks_copy, :email_copy, :sales_start_at, :sales_end_at, 
                  :on_sale, :price, :tickets_allowed, :starts_at, :ends_at

  validates :name, :description, :price, :tickets_allowed, :starts_at, :ends_at, :presence => true

  scope :storefront, where(:on_sale => true).where("sales_start_at < ? or sales_start_at is null", DateTime.now).where("sales_end_at > ? or sales_end_at is null", DateTime.now)
  scope :on_sale, where(:on_sale => true)
  scope :not_ended, where('ends_at > ?', DateTime.now)

  ALL_PASSES_STRING = "ALL PASSES"

  comma do
    name
    description
    price                      { |price| PassType.number_as_cents price }
    tickets_allowed
    passes 'Passes sold' do |p|
      p.count
    end
    starts_at
    ends_at
    on_sale
    sales_start_at
    sales_end_at
  end
  
  def sold
    self.passes.select{ |p| p.person_id.present? }
  end

  def passerize
    self.name.end_with?("Pass") ? self.name : self.name + " Pass"
  end

  def destroyable?
    self.passes.empty?
  end
end