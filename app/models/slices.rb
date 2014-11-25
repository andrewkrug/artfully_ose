###
#
# These procs are very similar to the code used in Statement.
# Future refactoring will feature a marriage of these two stalwart classes
# So as not to duplicate code.
#
# Combining the code isn't quite as easy as it first looks (which is why I haven't done it yet, also no unit tests)
#
###
class Slices
  cattr_accessor :payment_method_proc, 
                 :ticket_type_proc, 
                 :order_location_proc,
                 :discount_code_proc,
                 :first_time_buyer_proc,
                 :validated_proc

  self.payment_method_proc = Proc.new do |items|
    payment_method_map = {}
    items.each do |item|
      next if item.refund? || item.refunded? || item.exchanged?
      item_array = payment_method_map[item.order.payment_method]
      item_array ||= []
      item_array << item
      payment_method_map[item.order.payment_method] = item_array
    end
    payment_method_map.delete_if{ |k,v| v.empty? }
  end

  self.validated_proc = Proc.new do |items|
    validated_map = {}
    items.each do |item|
      next if item.refund? || item.refunded? || item.exchanged?
      kee = (item.product.validated? ? "VALIDATED" : "NOT VALIDATED")
      item_array = validated_map.fetch(kee, [])
      item_array << item
      validated_map[kee] = item_array
    end
    validated_map.delete_if{ |k,v| v.empty? }
  end

  self.ticket_type_proc = Proc.new do |items|
    ticket_type_map = {}
    items.each do |item|
      next if item.refund? || item.refunded? || item.exchanged?
      item_array = ticket_type_map.fetch(item.product.ticket_type.name, [])
      item_array << item
      ticket_type_map[item.product.ticket_type.name] = item_array
    end
    ticket_type_map.delete_if{ |k,v| v.empty? }
  end

  self.order_location_proc = Proc.new do |items|
    order_location_map = {}
    items.each do |item|
      next if item.refund? || item.refunded? || item.exchanged?
      order_location = item.order.original_order.location
      item_array = order_location_map[order_location]
      item_array ||= []
      item_array << item
      order_location_map[order_location] = item_array
    end
    order_location_map.delete_if{ |k,v| v.empty? }
  end

  self.discount_code_proc = Proc.new do |items|
    discounts_code_map = {}
    items.each do |item|
      next if item.refund? || item.refunded? || item.exchanged?
      code = item.discount.try(:code) || "NO DISCOUNT"
      item_array = discounts_code_map[code]
      item_array ||= []
      item_array << item 
      discounts_code_map[code] = item_array
    end
    discounts_code_map.delete_if{ |k,v| v.empty? }
  end

  #
  # Dog slow.  One query for each item.
  #
  self.first_time_buyer_proc = Proc.new do |items|
    first_time_buyer_map = {}
    items.each do |item|
      next if item.refund? || item.refunded? || item.exchanged?
      previous_action = GetAction.where(:person_id => item.order.person.id)
                                 .where('occurred_at < ?', item.order.created_at)
                                 .first
                                     
      kee = (previous_action.nil? ? "FIRST" : "RETURNING")
      item_array = first_time_buyer_map[kee]
      item_array ||= []
      item_array << item
      first_time_buyer_map[kee] = item_array
    end
    first_time_buyer_map.delete_if{ |k,v| v.empty? }
  end
end