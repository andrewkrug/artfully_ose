module Imports
  module Status
    # Import status transitions:
    #   pending -> approved -> imported
    
    def self.included(base)
      base.class_eval do
        attr_accessible :status
      end
    end
    
    
    def caching!
      save if new_record?
      self.update_column(:status, "caching")
      Delayed::Job.enqueue self
    end

    def pending!
      self.update_column(:status, "pending")
    end

    def approve!
      self.update_column(:status,"approved")
      Delayed::Job.enqueue self
    end

    def invalidate!
      self.update_column(:status, "invalid")
    end

    def importing!
      self.update_column(:status, "importing")
    end

    def imported!
      self.update_column(:status, "imported")
    end

    def recalling!
      self.update_column(:status, "recalling")
    end

    def recalled!
      self.update_column(:status, "recalled")
    end

    def failed!
      self.update_column(:status, "failed")
    end

    def failed?
      self.status == "failed"
    end
  end
end