class ImportRow < ActiveRecord::Base
  attr_accessible :content
  belongs_to :import

  validates_presence_of :import
  validates_associated :import
  validates_presence_of :content, :message => "is missing.  You have blank lines in your import file.  Please remove any blank lines (double-check the top and bottom of the file) and try again."

  serialize :content

end
