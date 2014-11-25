class User < ActiveRecord::Base

  include Ext::DeviseConfiguration
  include Ext::Integrations::User

  devise      :token_authenticatable
  before_save :ensure_authentication_token

  has_many :shows
  has_many :orders
  has_many :imports
  has_many :discounts

  has_many :user_memberships
  has_many :organizations, :through => :user_memberships

  scope :logged_in_more_than_once, where("users.sign_in_count > 1")

  def self.generate_password
    Devise.friendly_token
  end

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :user_agreement, :newsletter_emails, :first_name, :last_name, :user_memberships_attributes

  def is_in_organization?
    @is_in_organization ||= !!(user_memberships.any? && ! user_memberships.first.organization.new_record?)
  end

  def current_organization
    @current_organization ||= is_in_organization? ? user_memberships.first.organization : Organization.new
  end

  def membership_in(organization)
    user_memberships.where(:organization_id => organization.id).limit(1).first
  end

  def self.like(query = "")
    return if query.blank?
    q = "%#{query}%"
    self.joins("LEFT OUTER JOIN user_memberships m ON m.user_id = users.id")
        .joins("LEFT OUTER JOIN organizations o ON o.id = m.organization_id")
        .includes(:organizations)
        .where("users.email like ? or o.name like ?", q, q)
  end

  def active_for_authentication?
    super && !suspended?
  end

  def to_s
    if first_name.present? || last_name.present?
      [first_name, last_name].reject(&:blank?).join(" ")
    elsif email.present?
      email.to_s
    else
      "No Name ##{id}"
    end
  end
end
