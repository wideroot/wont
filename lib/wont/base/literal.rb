module 


class Literal < BasicLiteral
  def valid?; false; end
  def attr_internal_value
    {_type: self.class, _value: self}
  end
end


end
