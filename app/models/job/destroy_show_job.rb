class DestroyShowJob < Struct.new(:show)
  def initialize(show)
   @show = show
  end
  
  def perform
    @show.destroy
  end
  
end