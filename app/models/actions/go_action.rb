class GoAction < Action

  has_many :tickets, :foreign_key => "validated_action_id"

  def show
    subject
  end
  
  def action_type
    "Go"
  end
  
  def verb
    "went"
  end

  def sentence
    #TODO: YUK. Do we still have to do this to discriminate from manually logged actions?
    if subject.is_a? Show
      verb + " " + self.details
    else
      " to a show"
    end
  end
  
  def self.for(show, person, occurred_at=nil, &block)
    existing_action = GoAction.where({:subject_id => show.id, :person_id => person.id}).first
    return existing_action || GoAction.new.tap do |go_action|
      go_action.person = person
      go_action.subject = show
      go_action.details = "to #{show.event.name} on #{I18n.l show.parsed_local_datetime, :format => :short}"
      go_action.organization = show.organization
      time_zone = show.time_zone
      go_action.occurred_at = ( occurred_at.nil? ? show.parsed_local_datetime.beginning_of_day : occurred_at )
      block.call(go_action) if block.present?
    end
  end

  def self.subtypes
    []
  end
end