module Wont


class BasicLiteral < w(:Space)
  def valid?; true; end
  def attr_internal_value; self; end
  def assign_uid! recursive = true; nil; end
end


class Hash
  include BasicLiteral
end

class Array
  include BasicLiteral
end

class String
  include BasicLiteral
end

class Numeric
  include BasicLiteral
end

class FalseClass
  include BasicLiteral
end

class TrueClass
  include BasicLiteral
end

class NilClass
  include BasicLiteral
end


end
