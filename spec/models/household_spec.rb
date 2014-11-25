require 'spec_helper'

describe Household do

  it { should validate_uniqueness_of(:name) }
  it { should have_many :individuals }

end
