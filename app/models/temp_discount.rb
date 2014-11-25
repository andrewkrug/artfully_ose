# only exsist for mockuping up the discount form
# remove after Discount and DiscountSections model is created

class TempDiscount < Event
  attr_accessor :code, :active, :promotion_type, :minimum_purchase, :maximum_purchase, :show_ids, :limit, :unlimited_capacity

  has_many :discount_sections
end

class DiscountSection < Section
  attr_accessor :temp_discount_id, :section, :section_id

  attr_accessible :section
end