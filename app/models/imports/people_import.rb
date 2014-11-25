class PeopleImport < Import
  def kind
    "people"
  end
  
  def rollback
    self.people.destroy_all
  end

  def recallable?
    true if self.status == "imported"
  end

  def recall
    raise "Can't recall this import" unless recallable?
    self.import_messages.destroy_all
    self.recalling!

    no_errors = true
    self.people.each do |person|
      if person.destroyable?
        person.destroy
      else
        self.message(nil, nil, person, "#{person} had existing actions or orders, and wasn't able to be recalled.")
        no_errors = false
      end
    end

    self.recalled!
    no_errors
  end

  def process(parsed_row)
    create_person(parsed_row)
  end
  
  def row_valid?(parsed_row)
    #We're doing this here because the error message for naming_details_available? is very bad
    raise Import::RowError, "Please include a first name, last name, or email in this row: #{parsed_row.row}" unless attach_person(parsed_row).naming_details_available?
    
    #We're bypassing the valid? check that used to be here because we're allowing dupe emails (they get merged later)
    true
  end
  
  def error(parsed_row, person)
    message = ""
    message = parsed_row.email + ": " unless parsed_row.email.blank?
    message = message + person.errors.full_messages.join(", ")    
    raise Import::RowError, message
  end
  
  def create_person(parsed_row)
    new_person = attach_person(parsed_row)

    existing_person = Person.first_or_initialize( {:email => new_person.email, :organization => self.organization} ) do |p|
      p.import = self
      p.type = new_person.type
      p.subtype = new_person.subtype
    end
    message(nil, parsed_row, existing_person, "#{existing_person.email} exists. Will merge records.") unless existing_person.new_record?

    existing_person.update_from_import(new_person)
    existing_person.skip_commit = true
    if !existing_person.save
      error(parsed_row, existing_person)
    end
    existing_person  
  end
end