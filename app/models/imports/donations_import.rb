class DonationsImport < Import
  include Imports::Rollback
  include Imports::Validations
  include ArtfullyOseHelper
  
  def kind
    "donations"
  end
  
  def process(parsed_row)
    row_valid?(parsed_row)
    person        = create_person(parsed_row)
    contribution  = create_contribution(parsed_row, person)
  end
  
  def rollback 
    rollback_orders
    rollback_people
  end
  
  def validate_amounts(parsed_row)
    if !parsed_row.unparsed_nongift_amount.blank? && parsed_row.nongift_amount > parsed_row.amount
      raise Import::RowError, "Non-deductible amount (#{parsed_row.unparsed_nongift_amount}) cannot be more than the total doantion amount (#{parsed_row.unparsed_amount})': #{parsed_row.row}"
    end

    if !parsed_row.unparsed_deductible_amount.blank? && parsed_row.deductible_amount > parsed_row.amount
      raise Import::RowError, "Deductible amount (#{parsed_row.unparsed_deductible_amount}) cannot be more than the total doantion amount (#{parsed_row.unparsed_amount})': #{parsed_row.row}"
    end    
    
    if !parsed_row.unparsed_deductible_amount.blank? &&
       !parsed_row.unparsed_nongift_amount.blank? &&
       (parsed_row.deductible_amount + parsed_row.nongift_amount != parsed_row.amount)
      raise Import::RowError, "Deductible amount (#{parsed_row.unparsed_deductible_amount}) + Non-Deductible Amount (#{parsed_row.unparsed_nongift_amount}) does not equal Amount of  in this row: #{parsed_row.row}"
    end  
  end
  
  def row_valid?(parsed_row)
    raise Import::RowError, "No Amount included in this row: #{parsed_row.row}" if parsed_row.unparsed_amount.blank?
    raise Import::RowError, "Please include a first name, last name, email, or company name in this row: #{parsed_row.row}" unless attach_person(parsed_row).naming_details_available?
    raise Import::RowError, "Please include a payment method in this row: #{parsed_row.row}" if parsed_row.payment_method.blank?
    raise Import::RowError, "Donation type must be 'Monetary' or 'In-Kind': #{parsed_row.row}" unless GiveAction.subtypes.include? (parsed_row.donation_type)
    raise Import::RowError, "No Date included in this row: #{parsed_row.row}" unless parsed_row.donation_date
    valid_date?   parsed_row.donation_date
    
    [:unparsed_amount, :unparsed_nongift_amount, :unparsed_deductible_amount].each do |amt|
      valid_amount? parsed_row.send(amt)   unless parsed_row.send(amt).blank?
    end
    
    validate_amounts(parsed_row)
    true
  end
   
  def create_contribution(parsed_row, person)
    Rails.logger.info("Processing Import [#{id}] DONATION_IMPORT: Creating contribution")
    validate_amounts(parsed_row)
    amount              = parsed_row.amount
    deductible_amount   = parsed_row.unparsed_deductible_amount.blank?  ? amount - parsed_row.nongift_amount     : parsed_row.deductible_amount
    nongift_amount      = parsed_row.unparsed_nongift_amount.blank?     ? amount - deductible_amount             : parsed_row.nongift_amount
    
    occurred_at = parsed_row.donation_date.blank? ? time_zone_parser.now : time_zone_parser.parse(parsed_row.donation_date)
    params = {}
    params[:subtype] = parsed_row.donation_type
    params[:amount] = deductible_amount
    params[:nongift_amount] = nongift_amount
    params[:payment_method] = parsed_row.payment_method
    
    params[:organization_id] = self.organization.id
    params[:occurred_at] = occurred_at.to_s
    params[:details] = "Imported by #{user.email} on  #{I18n.l self.created_at_local_to_organization, :format => :date}"
    params[:person_id] = person.id
    params[:creator_id] = user.id
    
    contribution = Contribution.new(params)
    contribution.save(ImportedOrder) do |contribution|
      contribution.order.import_id  = self.id
      contribution.order.save
      contribution.order.reload
      contribution.action.import_id = self.id 
      contribution.action.creator = self.user
      contribution.action.details = "Donated #{number_as_cents contribution.order.total}"
      contribution.action.save
    end
    contribution
  end
end