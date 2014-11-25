class Array

  def to_h
    {}.tap do |hash|
      each do |e|
        k, v = yield(e)
        hash[k] = v
      end
    end
  end

end
