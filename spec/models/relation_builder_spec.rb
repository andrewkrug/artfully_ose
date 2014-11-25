require 'spec_helper'

describe RelationBuilder do

  it "creates a Relation an it's inverse" do
    rel = RelationBuilder.build("parent", "child", true, false, true, false)
    Relation.count.should == 2
    rel.inverse.should_not be_nil
    rel.inverse.inverse.should == rel
  end

  it "creates a Relation and self as inverse" do
    rel = RelationBuilder.build_single("friend", true, false, true, false)
    rel.inverse.should_not be_nil
    rel.inverse.should == rel
  end

end
