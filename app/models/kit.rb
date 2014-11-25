class Kit < ActiveRecord::Base
  include ActiveRecord::Transitions
  include Ext::Integrations::Kit
  default_scope :order => 'created_at DESC'
  belongs_to :organization
  validates_presence_of :organization

  class_attribute :requires_approval, :ability_proc, :configurable, :restricted_to_admins

  def self.visible
    where(Kit.arel_table[:state].eq("activated").or(Kit.arel_table[:state].eq('pending')))
  end

  def self.acts_as_kit(options = {}, &block)
    self.requires_approval = options.delete(:with_approval) || false
    self.restricted_to_admins = options.delete(:admin_only) || false

    state_machine do
      state :fresh
      state :pending, :enter => :on_pending
      state :activated, :enter => :on_activation
      state :cancelled

      event(:activate, :success => :record_activation)   { transitions :from => [:fresh, :pending], :to => :activated, :guard => :activatable? }
      event(:approve, :success => :record_approval)    { transitions :from => :pending, :to => :activated, :guard => :approvable? }
      event(:admin_approve, :success => :record_approval)    { transitions :from => :pending, :to => :activated, :guard => :admin_approvable? }
      event(:cancel)     { transitions :from => [:activated, :pending, :rejected ], :to => :cancelled }
      event(:reactivate) { transitions :from => :cancelled, :to => :activated, :guard => :activatable? }
      event(:activate_without_pending) { transitions :from => [:fresh, :pending, :cancelled], :to => :activated }
    end

    if self.requires_approval
      state_machine do
        event(:submit_for_approval) { transitions :from => :fresh, :to => :pending }
      end
    end

    class_eval(&block)
    self
  end

  def self.activate(options)
    activation_requirements[:unless] << options.delete(:unless) if options.has_key?(:unless)
    activation_requirements[:if] << options.delete(:if) if options.has_key?(:if)
  end

  def self.approve(options)
    approval_requirements[:unless] << options.delete(:unless) if options.has_key?(:unless)
    approval_requirements[:if] << options.delete(:if) if options.has_key?(:if)
  end

  def self.admin_approve(options)
    admin_approval_requirements[:unless] << options.delete(:unless) if options.has_key?(:unless)
    admin_approval_requirements[:if] << options.delete(:if) if options.has_key?(:if)
  end

  def self.activation_requirements
    @requirements ||= Hash.new { |h,k|  h[k] = [] }
  end

  def self.approval_requirements
    @approval_requirements ||= Hash.new { |h,k|  h[k] = [] }
  end

  def self.admin_approval_requirements
    @admin_approval_requirements ||= Hash.new { |h,k|  h[k] = [] }
  end

  def self.when_active(&block)
    self.ability_proc = Proc.new(&block)
  end

  def self.subklasses
    @subklasses ||= [ TicketingKit, RegularDonationKit, SponsoredDonationKit, ResellerKit, MailchimpKit, MembershipKit, PassesKit, ScannableTicketsKit, RelationshipsKit ].freeze
  end

  def self.pad_with_new_kits(kits = [])
    types = kits.collect(&:type)
    alternatives = kits.collect(&:alternatives).flatten.uniq

    padding = subklasses.reject{ |klass| klass.to_s == "SponsoredDonationKit" }.reject{ |klass| (types.include? klass.to_s) or (alternatives.include? klass) }.collect(&:new)
    kits + padding
  end

  def self.mailchimp
    find_by_type("MailchimpKit")
  end

  def abilities
    activated? ? self.class.ability_proc : Proc.new {}
  end

  def has_alternatives?
    alternatives.any?
  end

  def alternatives
    []
  end

  def requirements_met?
    check_requirements
  end

  def activatable?
    return false if organization.nil?

    if needs_approval?
      check_requirements
      submit_for_approval!
      return false
    end

    check_requirements
  end

  def approvable?
    check_approval
  end

  def admin_approvable?
    check_admin_approval
  end

  class DuplicateError < StandardError
  end

  protected
    def on_activation; end
    def on_pending; end

    def dont_approve
      false
    end

  private
    def check_requirements
      check_unlesses(self.class.activation_requirements[:unless]) and check_ifs(self.class.activation_requirements[:if])
    end

    def check_approval
      check_unlesses(self.class.approval_requirements[:unless]) and check_ifs(self.class.approval_requirements[:if])
    end

    def check_admin_approval
      check_unlesses(self.class.admin_approval_requirements[:unless]) and check_ifs(self.class.admin_approval_requirements[:if])
    end

    def check_unlesses(unlesses)
      return true if unlesses.empty?
      unlesses.all? { |req| !self.send(req) }
    end

    def check_ifs(ifs)
      return true if ifs.empty?
      ifs.all? { |req| self.send(req) }
    end

    def needs_approval?
      self.class.requires_approval and fresh?
    end
end
