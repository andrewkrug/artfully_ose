module OhNoes
  module Destroy
    extend ActiveSupport::Concern
    
    included do
      default_scope where(:deleted_at => nil)
    end
  
    # options:
    # :with_prejudice => true, will not check destroyable?
    delegate :destroy!, :to => :destroy
    def destroy(options = {})
      return false unless destroyable? || !!options[:with_prejudice]
      run_callbacks :destroy do
        update_column(:deleted_at, Time.now)
      end
    end
    
    def destroyable?
      true
    end
  
  end
end