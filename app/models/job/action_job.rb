#
# Callers should:
# - set all relevant details on :action including org and creator.
# - call action.to_open_struct, then pass that struct to this Job
#
# If action.subject is not set, subject will be set to person_id 
#
class ActionJob < Struct.new(:action_struct, :people_ids)
  def initialize(action, people)
    self.action_struct = action.to_open_struct
    self.people_ids = Array.wrap(people).map(&:id)
  end

  def perform
    action = Action.from_open_struct(self.action_struct)
    ActiveRecord::Base.transaction do
      
      Person.where(:id => self.people_ids).each do |p|
        if action.organization_id != p.organization_id
          raise "Org id on action #{action.organization_id} does not equal org id on person with id #{p.id}"
        end
        new_action = action.dup
        new_action.subject_id ||= p.id
        new_action.person = p
        new_action.save
      end
    end
  end
end