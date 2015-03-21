module Wont


module BasicLiteral
  def valid?; true; end
  def attr_internal_value; self; end
  def assign_uid! recursive = true; nil; end
end


end


class Hash
  include Wont::BasicLiteral
end

class Array
  include Wont::BasicLiteral
end

class String
  include Wont::BasicLiteral
end

class Numeric
  include Wont::BasicLiteral
end

class FalseClass
  include Wont::BasicLiteral
end

class TrueClass
  include Wont::BasicLiteral
end

class NilClass
  include Wont::BasicLiteral
end
