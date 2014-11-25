BRAINTREE_GENERIC_REJECT = "We're sorry but we could not process your credit card.  Please check the details and try again."

BRAINTREE_REJECT_MESSAGE_MAPPING = Hash.new(BRAINTREE_GENERIC_REJECT)
BRAINTREE_REJECT_MESSAGE_MAPPING["CVV must be 4 digits for American Express and 3 digits for other card types (81707)"] = "CVV is invalid. CVV must be 4 digits for American Express and 3 digits for other card types."
BRAINTREE_REJECT_MESSAGE_MAPPING["2004 Expired Card"] = "We're sorry but we could not process your credit card.  It looks like your card has expired."