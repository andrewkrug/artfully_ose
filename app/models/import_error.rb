class ImportError < ActiveRecord::Base

  attr_accessible :error_message, :row_data
  belongs_to :import

  serialize :row_data

end
