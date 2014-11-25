#
# This is for use with session-based carts. Token-based carts (V3 widget)
# can't use these methods
#
module CartFinder
  extend ActiveSupport::Concern

  included do |c|
    c.helper_method :current_cart
    c.helper_method :current_sales_console_cart
  end

  def current_sales_console_cart
    current_cart(ConsoleSale::Cart)
  end

  def current_box_office_cart
    current_cart(BoxOffice::Cart)
  end

  def current_cart(klass = Cart)
    (!session_cart(klass) || session_cart(klass).approved?) ? create_new_cart(klass) : session_cart(klass)
  end

  def session_cart(klass = Cart)
    @current_cart ||= Cart.find_by_id(session[session_key(klass)])
  end

  def create_new_cart(klass = Cart)
    @current_cart = klass.create
    session[session_key(klass)] = @current_cart ? @current_cart.id : nil
    @current_cart
  end

  #
  # Use with care. Only assign updated carts (in the case of discounts)
  # TODO: Enforce that this isn't used to actually switch to another cart object
  #
  def current_cart=(cart)
    @current_cart = cart
  end

  def cart_name(klass = Cart)
    klass.name.gsub("::","").underscore
  end

  def session_key(klass)
    (cart_name(klass) + "_id").to_sym
  end
end