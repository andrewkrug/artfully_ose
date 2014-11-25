class Note < ActiveRecord::Base
  attr_accessible :occurred_at, :text
  
  belongs_to :person, touch: true
  belongs_to :user
  belongs_to :organization
end

