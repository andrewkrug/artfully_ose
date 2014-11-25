require 'spec_helper'

describe Statement do
  include ActiveMerchantTestHelper
  include SalesTestHelper
  disconnect_sunspot 
  
  let(:event)           { FactoryGirl.create(:event) }
  let(:super_code)      { FactoryGirl.create(:discount, :code => "SUPER", :properties => HashWithIndifferentAccess.new( amount: 200 ), :event => event) }
  let(:other_code)      { FactoryGirl.create(:discount, :code => "OTHER", :properties => HashWithIndifferentAccess.new( amount: 100 ), :event => event) }
  let(:organization)    { FactoryGirl.create(:organization) } 
  let(:paid_chart)      { FactoryGirl.create(:chart, :event => event, :price => 1000, :capacity => 10) }
  let(:free_chart)      { FactoryGirl.create(:chart, :event => event, :capacity => 10) }
  let(:exchangee_show)  { FactoryGirl.create(:show_with_tickets, :organization => organization, :chart => paid_chart, :event => event) }
  let(:paid_show)       { FactoryGirl.create(:show_with_tickets, :organization => organization, :chart => paid_chart, :event => event) }
  let(:free_show)       { FactoryGirl.create(:show_with_tickets, :organization => organization, :chart => free_chart, :event => event) }
  let(:blue_pass_type)  { FactoryGirl.create(:pass_type, :organization => organization) }

  describe "nil show" do
    it "should return an empty @statement if the show is nil" do
      st = Statement.for_show(nil)
      st.should_not be_nil
      st.tickets_sold.should be_nil
    end
  end
  
  describe "free show" do     
  end
  
  describe "no tickets sold" do      
    before(:each) do
      @statement = Statement.for_show(paid_show)
    end
      
    it "should calculate everything correctly" do
      @statement.datetime.should eq paid_show.datetime
      @statement.tickets_sold.should eq 0
      @statement.tickets_comped.should eq 0
      @statement.gross_revenue.should eq 0
      @statement.processing.should be_within(0.00001).of(0)
      @statement.net_revenue.should eq 0
      @statement.payment_method_rows.length.should eq 3 
      @statement.discount_rows.length.should eq 0     
    end    
  end
  
  describe "three credit card sales and three comps" do    
    before(:each) do
      setup_tickets(true)
      @statement = Statement.for_show(paid_show.reload)
    end
      
    it "should calculate everything correctly" do
      @statement.datetime.should eq paid_show.datetime
      @statement.tickets_sold.should eq 3
      @statement.tickets_comped.should eq 3
      @statement.gross_revenue.should eq 2500
      @statement.processing.should be_within(0.00001).of((2500 * 0.035).round)
      @statement.net_revenue.should eq (@statement.gross_revenue - @statement.processing)
      
      @statement.payment_method_rows.length.should eq 3
      
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].should_not be_nil
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].tickets.should eq 3
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].gross.should eq 2500
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].processing.should be_within(0.00001).of((2500 * 0.035).round)
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].net.should eq 2412
      
      @statement.payment_method_rows[::CompPayment.payment_method.downcase].should_not be_nil
      @statement.payment_method_rows[::CompPayment.payment_method.downcase].tickets.should eq 3
      @statement.payment_method_rows[::CompPayment.payment_method.downcase].gross.should eq 0
      @statement.payment_method_rows[::CompPayment.payment_method.downcase].processing.should be_within(0.00001).of(0)
      @statement.payment_method_rows[::CompPayment.payment_method.downcase].net.should eq 0
      
      @statement.payment_method_rows[::CashPayment.payment_method.downcase].should_not be_nil
      @statement.payment_method_rows[::CashPayment.payment_method.downcase].tickets.should eq 0
      @statement.payment_method_rows[::CashPayment.payment_method.downcase].gross.should eq 0
      @statement.payment_method_rows[::CashPayment.payment_method.downcase].processing.should be_within(0.00001).of(0)
      @statement.payment_method_rows[::CashPayment.payment_method.downcase].net.should eq 0
      
      @statement.order_location_rows[::WebOrder.location].should_not be_nil   
      @statement.order_location_rows[::WebOrder.location].tickets.should eq 3 
      
      @statement.order_location_rows[BoxOffice::Order.location].should_not be_nil   
      @statement.order_location_rows[BoxOffice::Order.location].tickets.should eq 0 
      
      @statement.order_location_rows[CompOrder.location].should_not be_nil   
      @statement.order_location_rows[CompOrder.location].tickets.should eq 3

      @statement.discount_rows.length.should eq 2
      @statement.discount_rows[super_code.code].tickets.should eq 2
      @statement.discount_rows[super_code.code].discount.should eq 400

      @statement.discount_rows[other_code.code].tickets.should eq 1
      @statement.discount_rows[other_code.code].discount.should eq 100
    end
  end
  
  describe "with an exchange" do      
    before(:each) do
      setup_tickets
      setup_exchange
      @statement = Statement.for_show(paid_show.reload)
    end
      
    it "should calculate everything correctly" do
      @statement.datetime.should eq paid_show.datetime
      @statement.tickets_sold.should eq 4
      @statement.tickets_comped.should eq 3
      @statement.gross_revenue.should eq 4000
      @statement.processing.should be_within(0.00001).of(4000 * 0.035)
      @statement.net_revenue.should eq (@statement.gross_revenue - @statement.processing)
      
      @statement.payment_method_rows.length.should eq 3
      
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].should_not be_nil
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].tickets.should eq 4
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].gross.should eq 4000
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].processing.should be_within(0.00001).of(4000 * 0.035)
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].net.should eq 3860
      
    end  
  end
  
  describe "with a refund" do      
    before(:each) do
      setup_tickets
      setup_refund
      @statement = Statement.for_show(paid_show.reload)
    end
      
    it "should calculate everything correctly" do
      @statement.datetime.should eq paid_show.datetime
      
      @statement.tickets_sold.should eq 2
      @statement.tickets_comped.should eq 3
      @statement.gross_revenue.should eq 2000
      @statement.processing.should be_within(0.00001).of(2000 * 0.035)
      @statement.net_revenue.should eq (@statement.gross_revenue - @statement.processing)
    
      @statement.payment_method_rows.length.should eq 3
      
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].should_not be_nil
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].tickets.should eq 2
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].gross.should eq 2000
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].processing.should be_within(0.00001).of(2000 * 0.035)
      @statement.payment_method_rows[::CreditCardPayment.payment_method.downcase].net.should eq 1930
      
    end  
  end
  
  describe "with a pass" do      
    before(:each) do
      @blue_pass = Pass.for(blue_pass_type)
      @blue_pass.save
      @blue_pass.stub(:applies_to?).and_return(true)
      @blue_pass.stub(:tickets_allowed).and_return(10)
      @blue_pass.stub(:expired?).and_return(false)
      @blue_pass.stub(:applies_to?).and_return(true)
      @blue_pass.stub(:tickets_remaining_for).and_return(10)
      setup_tickets(false, @blue_pass)
      @statement = Statement.for_show(paid_show.reload)
    end
      
    it "should calculate everything correctly" do
      @statement.pass_rows.length.should eq 1
    end  
  end

  def setup_tickets(use_discounts = false, pass = nil)
    ticket_type = paid_show.chart.sections.first.ticket_types.first

    if use_discounts
      @paid_cart_super, order = buy(paid_show.tickets[0..1], ticket_type, {:discount => super_code})
      @paid_cart_other, @to_be_refunded = buy(paid_show.tickets[2], ticket_type, {:discount => other_code})
    elsif pass.present?
      @paid_cart_super, order = buy(paid_show.tickets[0..1], ticket_type, {:pass => pass})
    else
      @paid_cart_super, order = buy(paid_show.tickets[0..1], ticket_type)
      @paid_cart_other, @to_be_refunded = buy(paid_show.tickets[2], ticket_type)
    end
    comp(paid_show, paid_show.tickets[3..5], paid_show.chart.sections.first.ticket_types.first)
  end
  
  def setup_exchange
    ticket_type = paid_show.chart.sections.first.ticket_types.first
    @exchange_cart = Cart.new
    Ticket.lock(exchangee_show.tickets[0], ticket_type, @exchange_cart)
    checkout = Checkout.new(@exchange_cart, FactoryGirl.build(:credit_card_payment))
    checkout.finish
    exchange = Exchange.new(checkout.order, Array.wrap(checkout.order.items.first), Array.wrap(paid_show.tickets[6]), FactoryGirl.create(:ticket_type))
    exchange.submit
  end
  
  def setup_refund
    gateway.stub(:refund).and_return(successful_response)
    refund = Refund.new(@to_be_refunded, @to_be_refunded.items)
    refund.submit({:and_return => true})
  end
end