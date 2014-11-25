class TagJob < Struct.new(:tag, :people_ids)
  def initialize(tag, people)
    self.tag = tag
    self.people_ids = Array.wrap(people).map(&:id)
  end

  def perform
    Person.where(:id => self.people_ids).each do |p|
      p.tag_list << self.tag unless p.tag_list.include? self.tag
      p.skip_commit = true
      p.save
    end
    Sunspot.delay.commit
  end
end