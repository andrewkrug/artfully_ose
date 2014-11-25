class Action < ActiveRecord::Base
  include OhNoes::Destroy
  
  belongs_to :person, touch: true
  belongs_to :creator, :class_name => "User", :foreign_key => "creator_id"
  belongs_to :organization
  belongs_to :subject, :polymorphic => true
  belongs_to :import

  validates_presence_of :occurred_at
  validates_presence_of :person_id

  before_save :default_starred_to_false

  set_watch_for :occurred_at, :local_to => :organization

  def self.for_organization(organization)
    #Skipping whitelisting because we're playing on our home field
    Kernel.const_get(self.name.camelize).new({:occurred_at  => DateTime.now.in_time_zone(organization.time_zone), 
                                              :organization => organization},
                                              :without_protection => true)
  end

  #
  # Action types: give, go, do, get, join, hear
  #
  def self.create_of_type(type)
    case type
      when "hear" then HearAction.new
      when "say" then SayAction.new
      when "go" then GoAction.new
      when "give" then GiveAction.new
      when "do" then DoAction.new
    end
  end

  def self.subtypes_by_type
    {
      "hear" => HearAction.subtypes,
      "say" => SayAction.subtypes,
      "go" => GoAction.subtypes,
      "give" => GiveAction.subtypes,
      "do" => DoAction.subtypes,
      "get" => GetAction.subtypes
    }
  end

  # destroyable? is mixed-in from ohnoes.rb
  def editable?
    true
  end

  #
  # set_params and set_creator need to be wrapped up into an initialize method
  #
  def set_params(params, person)
    params ||= {}

    self.occurred_at = ActiveSupport::TimeZone.create(Organization.find(self.organization_id).time_zone).parse(params[:occurred_at]) if params[:occurred_at].present?
    self.subtype = params[:subtype]
    self.details = params[:details]

    self.person = person
    self.subject = person
  end

  def set_creator(user)
    self.creator_id = user.id
    self.organization_id = user.current_organization.id
  end

  def unstarred?
    !starred?
  end
  
  def verb
    verb
  end
  
  def quip
    verb
  end
  
  def sentence
    verb + " " + details
  end
  
  def full_details
    details
  end
  
  #This returnes an ARel, so you can chain
  def self.recent(organization)
    Action.includes(:person, :subject).where(:organization_id => organization).order('occurred_at DESC')
  end

  def self.subtypes
    []
  end

  def default_starred_to_false
    self.starred = false if self.starred.blank?
    true
  end

  #
  # This exists solely so that DJ can serialize an unsaved action so that ActionJob can run
  # There's nothing inherent to Action in this method so it looks like a good candidate to 
  # move into a Module.  But, I'm not thrilled with it and don't want it used willy-nilly
  # Perhaps in an DelayedJob::Unsaved::Serializable Module or something. 
  #
  def to_open_struct
    action_struct = OpenStruct.new
    self.class.column_names.each do |col|
      action_struct.send("#{col}=", self.send(col))
    end
    action_struct
  end

  def self.from_open_struct(action_struct)
    action = Kernel.const_get(action_struct.type).new
    Kernel.const_get(action_struct.type).column_names.each do |col|
      action.send("#{col}=", action_struct.send(col)) unless action_struct.send(col).nil?
    end
    action    
  end
end
