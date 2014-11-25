class ImportMessage < ActiveRecord::Base
  include OhNoes::Destroy
  belongs_to :import 
  belongs_to :person
  attr_accessible :import_id, :message, :row_number, :row_data, :person
end