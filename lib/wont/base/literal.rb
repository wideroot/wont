module Wont


require_wambda 'base/basic_literal'


class Literal < Instance
  include BasicLiteral
  def valid?; false; end
  def attr_internal_value
    {'_type' => self.class, '_value' => self}
  end
end


end
