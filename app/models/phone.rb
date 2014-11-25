class Phone < ActiveRecord::Base
  attr_accessible :kind, :number
  belongs_to :person

  def self.kinds
    [ "Work", "Home", "Cell", "Fax", "Other" ]
  end
end
