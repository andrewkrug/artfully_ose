require 'spec_helper'

describe "Finding carts" do
  class Carty
    attr_accessor :session
  end

  before(:each) do
    @carty = Carty.new
    @carty.session = {}
    @carty.extend(CartFinder)
  end

  it "should return a new cart if there is no cart" do
    Cart.stub(:find_by_id).and_return(nil)
    cart = @carty.current_cart
    is_a_cart = (cart.is_a? Cart)
    is_a_cart.should be_true
  end

  it "should return an existing cart if there's an id in the session" do
    cart = Cart.create
    @carty.session[:cart_id] = cart.id
    @carty.current_cart.should eq cart
  end

  it "should not lookup the cart in the DB more than once" do
    cart = Cart.create
    @carty.session[:cart_id] = cart.id
    Cart.should_receive(:find_by_id).once
    @carty.current_cart
    @carty.current_cart
  end

  it "should return a new cart if the session cart is approved" do
    cart = Cart.create
    cart.approve!
    cart.save
    @carty.session[:cart_id] = cart.id
    @carty.current_cart.should_not eq cart
  end

  it "should return the cart that was assigned" do
    cart1 = Cart.create
    @carty.session[:cart_id] = cart1.id
    @carty.current_cart.should eq cart1

    cart2 = Cart.create
    @carty.current_cart = cart2
    @carty.current_cart.should eq cart2
  end

  it "should return a box office cart" do
    box_office_cart = @carty.current_box_office_cart
    box_office_cart.class.should eq BoxOffice::Cart

    @carty.current_cart = nil

    cart = @carty.current_cart
    cart.class.should eq Cart

    box_office_cart.id.should_not eq cart.id
  end

  it "should return a sales console cart" do
    sales_console_cart = @carty.current_sales_console_cart
    sales_console_cart.class.should eq ConsoleSale::Cart

    @carty.current_cart = nil

    cart = @carty.current_cart
    cart.class.should eq Cart

    sales_console_cart.id.should_not eq cart.id
  end
end