module Imports
  module Rollback  
    def rollback_orders
      Order.where(:import_id => self.id).where(:organization_id => self.organization.id).all.each {|o| o.destroy(:with_prejudice => true)}
    end
  
    def rollback_people 
      Rails.logger.debug "ROLLING BACK PEOPLE"
      Person.where(:import_id => self.id).where(:organization_id => self.organization.id).all.each do |p|
        Rails.logger.debug "Destroying [#{p.id}]"
        result = p.destroy(:with_prejudice => true)
        Rails.logger.debug result
      end
    end
  end
end