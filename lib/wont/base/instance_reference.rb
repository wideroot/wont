module Wont


class InstanceReference < Literal
  def initialize instance
    @instance = instance
  end

  def attr_internal_value
    @instance.internal_value
  end
end


end
