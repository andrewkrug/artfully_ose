require 'spec_helper'

describe Relation do

  it "has an inverse relation" do
    rel1 = Relation.create(:description => "a to b")
    rel2 = rel1.create_inverse(:description => "b to a")
    rel1.save!
    rel2.inverse = rel1
    rel2.save!

    rel1.reload
    rel2.reload

    rel1.inverse.should == rel2
    rel1.inverse.inverse.should == rel1

  end

  it "inverse relation can be self" do
    rel1 = Relation.create(:description => "a to b")
    rel1.inverse = rel1
    rel1.save

    rel1.reload
    rel1.inverse.should == rel1
  end

  it "has an indefinite article that is guessed based on the description" do
    Relation.new(:description => "Advocate").indefinite_article.should eq "an"
    Relation.new(:description => "Educator").indefinite_article.should eq "an"
    Relation.new(:description => "Idol").indefinite_article.should eq "an"
    Relation.new(:description => "Obstitrician").indefinite_article.should eq "an"
    Relation.new(:description => "Undertaker").indefinite_article.should eq "an"

    Relation.new(:description => "Youth Advisor").indefinite_article.should eq "a"
    Relation.new(:description => "Manager").indefinite_article.should eq "a"
  end

end
