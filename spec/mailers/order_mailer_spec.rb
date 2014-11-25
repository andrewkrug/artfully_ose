require "spec_helper"

describe OrderMailer do
  disconnect_sunspot
  describe "order confirmation email" do
    let(:order) { FactoryGirl.create(:order) }
    subject { OrderMailer.confirmation_for(order) }

    before(:each) do
      order.stub(:items).and_return(10.times.collect{ FactoryGirl.create(:item)})
      order.stub(:contact_email).and_return("mo@zilla.com")
      subject.deliver
    end

    it "should send a confirmation email to the user" do
      ActionMailer::Base.deliveries.should_not be_empty
    end

    it "should have a subject" do
      subject.subject.should_not be_blank
      subject.subject.should eq "Your Order"
    end

    it "should be sent to the owner of the order" do
      subject.to.should_not be_blank
      subject.to.should include order.person.email
    end

    it "should set the reply_to correctly" do
      subject.reply_to.should == ["mo@zilla.com"]
    end

    # The following looks extremely awkward. But it's the only
    # way I can test calls to the environment variable, as far
    # as I can tell.
    context "when contact_email env. variable is not set" do
      it "clears the environment variable first" do
        ARTFULLY_CONFIG[:contact_email] = nil
      end
      it "should be sent from the order's contact email" do
        subject.from.should == ["mo@zilla.com"]
      end
    end
    context "when contact_email env. variable is set" do
      it "sets the environment variable first" do
        ARTFULLY_CONFIG[:contact_email] = "envvar@artful.ly"
      end
      it "should be sent from the order's contact email" do
        subject.from.should == ["envvar@artful.ly"]
      end
    end
  end
end
