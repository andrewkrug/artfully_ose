class MembershipsImport < Import
  include Imports::Rollback
  include Imports::Validations
  
  def kind
    "memberships"
  end
  
  def row_valid?(parsed_row)
    raise Import::RowError, "No Amount included in this row: #{parsed_row.row}" if parsed_row.unparsed_amount.blank?
    raise Import::RowError, "Please include a first name, last name, email, or company name in this row: #{parsed_row.row}" unless attach_person(parsed_row).naming_details_available?
    raise Import::RowError, "Please include a payment method in this row: #{parsed_row.row}" if parsed_row.payment_method.blank?
    valid_amount? parsed_row.unparsed_amount      unless parsed_row.unparsed_amount.blank?
    valid_date?   parsed_row.order_date           unless parsed_row.order_date.blank?
    true
  end
  
  def process(parsed_row)
    row_valid?(parsed_row)
    membership_type        = create_membership_type(parsed_row)
    person                 = create_person(parsed_row)
    order                  = create_order(parsed_row, person, membership_type)
    actions                = create_actions(parsed_row, person, memberships_type)
  end

  def create_membership_type(parsed_row)
    membership_type = self.organization.membership_types.build({
      :name => parsed_row.membership_name
    })
    membership_type.plan = parsed_row.membership_plan
    membership_type
  end

  def create_order(parsed_row, person, membership_type)
    #get order from hash
    # for 0 to parsed_row.number_of_memberships
         # create an item for this membership_type
    #add the item to the order
    #save the order
    #update get_action
    #hash order by order key (person, membership_type, payment_method)
  end
end