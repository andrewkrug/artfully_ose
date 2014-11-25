class PassSummary
  attr_accessor :organization, :passes, :rows
  
  def initialize(organization, passes)
    @organization = organization
    @passes = passes
    @rows = {}
    process_passes
  end

  def process_passes
    @passes.each do |pass|
      pass_type_array = @rows.fetch(pass.pass_type, [])
      pass_type_array << pass
      @rows[pass.pass_type] = pass_type_array
    end
  end
end