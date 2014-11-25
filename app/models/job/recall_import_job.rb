class RecallImportJob < Struct.new(:import_id)
  def perform
    Import.find(self.import_id).recall
  end
end
