class PersonLifetimeValueJob
  def perform
    Person.includes(:orders => :items).find_each do |p|
      p.skip_commit = true
      p.calculate_lifetime_value
      p.calculate_lifetime_donations
    end
    Sunspot.delay.commit
  end
end